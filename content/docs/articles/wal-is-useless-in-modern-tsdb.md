---
title: TSDB 不需要 WAL
date: 2024-10-31T16:54:10+08:00
description: 本文分析了 WAL 在时序数据库场景的应用，解释为何 TSDB 不像其他 DB 一样需要 WAL。
weight: 3
---

[Write-Ahead Log](https://en.wikipedia.org/wiki/Write-ahead_logging)（WAL）是现代 TSDB 中的常见机制：
- [Prometheus 使用 WAL](https://prometheus.io/docs/prometheus/latest/storage/#on-disk-layout)
- [InfluxDB 使用 WAL](https://docs.influxdata.com/influxdb/v1.7/concepts/storage_engine/#write-ahead-log-wal)
- [TimescaleDB 暂时性地 使用 PostgreSQL 的 WAL](https://docs.timescale.com/v1.2/getting-started/configuring#config-docker)
- [Cassandra 也使用 WAL](https://docs.datastax.com/en/cassandra/3.0/cassandra/dml/dmlHowDataWritten.html)。

让我们来看看 WAL 理论。  
WAL 用于防止在断电时丢失最近添加的数据。所有写入的数据必须在返回`success`给客户端之前写入预写日志。这保证了在断电后可以从`WAL`文件中恢复数据。理论上看起来简单而且很棒！那么在实践中呢？

## Page Cache 和 WAL
数据库开发人员都知道操作系统（OS）不会在每次 [write syscall](http://man7.org/linux/man-pages/man2/write.2.html) 时将数据写入磁盘。数据只是驻留在 [page cache](https://en.wikipedia.org/wiki/Page_cache#Disk_writes)，除非使用 [direct IO](https://github.com/facebook/rocksdb/wiki/Direct-IO)。因此，成功写入`WAL`文件的数据在断电时可能会消失。如何处理这个问题？要么使用 [繁琐的 direct IO](https://lkml.org/lkml/2002/5/11/58)，要么通过 [fsync syscall](http://man7.org/linux/man-pages/man2/fdatasync.2.html) 明确告诉操作系统将最近写入的数据从 page cache 刷新到磁盘。但是`fsync`有一个致命的缺点，就是在 SSD 上非常慢（1K-10K rps），在 HDD 上更慢（100 rps）。例如，`1M/s`写入速度可能会因使用`fsync-after-each-inserted-row`直接降成`100/s`。

数据库开发人员如何处理慢速的 `fsync`？他们通过各种方式放宽数据安全保证：

* Prometheus 仅在大量数据（即`segment`）写入`WAL`后才[调用 fsync](https://github.com/prometheus/tsdb/blob/bc3b0bd429153ab54662a930df3817e4f29d169e/wal/wal.go#L390)，因此在断电前所有`segment`数据可能会丢失/损坏。如果操作系统将写入数据的几个页面刷新到磁盘，但没有刷新剩余的页面，数据可能会损坏。Prometheus 默认每`2`小时对`segment`进行`fsync`，因此在硬件故障时可能会损坏大量数据。
* Cassandra 默认每`10`秒才对`WAL`[调用一次 fsync](https://stackoverflow.com/questions/31032156/cassandra-is-configured-to-lose-10-seconds-of-data-by-default)，因此在断电时最后`10`秒的数据可能会丢失/损坏。可能在这种情况下，多副本可以有所帮助。
* InfluxDB 默认在每个写请求上调用`fsync`，因此 InfluxDB 建议一次写请求包含`5K-10K`个数据点，以缓解`fsync`的拖垮性能。它[建议](https://docs.influxdata.com/influxdb/v1.7/administration/config/#wal-fsync-delay-0s)对于高写入量的场景或使用了读写速度慢的 HDD，将`wal-fsync-delay`设置为非零值，因此在断电时数据可能会丢失。
* TimescaleDB 依赖于 PostgreSQL 的`WAL`机制，该机制[将数据放入 RAM 中的 WAL 缓冲区并定期将其刷新到 WAL 文件](https://www.postgresql.org/docs/11/runtime-config-wal.html)。这意味着在断电或进程崩溃时，未刷新的`WAL`缓冲区中的数据将丢失。

因此，现代 TSDB 提供了“宽松的数据安全保证”，即最近插入的数据都可能会在断电时丢失。由此产生以下问题：
* 这些放宽措施是否违背了预写日志的主要目的？恕我直言，这个问题的答案是“是的”。
* 是否存在具有类似数据安全保证的更好方法？是的，那就是 [SSTable](https://stackoverflow.com/questions/2576012/what-is-an-sstable)。

## SSTable 代替 WAL?

这个想法很简单，只需将数据缓存在内存中，并以原子方式将其刷新到磁盘上。数据存储在类似 SSTable 的数据结构中，无需 WAL。

刷新可以通过超时（即每`N`秒）或达到最大缓冲区大小来触发。这提供了与上面`WAL`近似的数据安全保证，即最近插入的数据可能会在断电/进程崩溃时丢失。

细心的读者可能会注意到区别，WAL 可能导致数据损坏，而“直接写入 SSTable”方法容易受到进程崩溃的影响。恕我直言，进程崩溃时最近写入的数据丢失的严重性远低于数据损坏。数据库优雅关闭实现得好可以明显降低数据丢失的风险。优雅关闭程序非常简单，停止接收新数据，然后将内存缓冲区刷新到磁盘，然后退出。

以下数据库倾向于直接写入 SSTable 而不是 WAL：

* [ClickHouse](https://clickhouse.yandex/)。默认情况下，它将传入数据直接写入类似 SSTable 的磁盘。它通过 [Buffer](https://clickhouse.yandex/docs/en/operations/table_engines/buffer/) 表支持内存缓冲。
* [VictoriaMetrics](https://victoriametrics.com/)。它将传入数据缓存在 RAM 中，并定期将其刷新到磁盘上的类似 SSTable 的数据结构中。刷新间隔硬编码为一秒。
    

## 结论

WAL 的使用在现代 TSDB 中看起来是有问题的。它不能保证在断电时最近写入数据的安全性。而且 WAL 还有两个额外的缺点：

* 预写日志往往会消耗大量的磁盘IO。由于这个缺点，建议将`WAL`放在一个单独的物理磁盘上。直接写入 SSTable 方法消耗[更少的磁盘 IO](https://medium.com/@valyala/high-cardinality-tsdb-benchmarks-victoriametrics-vs-timescaledb-vs-influxdb-13e6ee64dd6b)，因此数据库可以在没有 WAL 的情况下处理更高的数据写入量。
* WAL 可能会由于缓慢的恢复行为[减慢数据库启动时间](https://groups.google.com/forum/m/#!topic/prometheus-users/l1AXuLtQnR0)，甚至可能导致 [OOM 和崩溃循环](https://github.com/prometheus/prometheus/issues/4833)。

Prometheus、InfluxDB 和 Cassandra 已经使用了[类似 LSM](https://en.wikipedia.org/wiki/Log-structured_merge-tree) 的数据结构和 SSTables，因此它们可以快速切换到新方法。目前尚不清楚 TimescaleDB 是否可以使用新方法，因为它不使用 LSM。
