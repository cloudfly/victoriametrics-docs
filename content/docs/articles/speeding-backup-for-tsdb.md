---
title: 备份加速
date: 2024-10-31T16:57:04+08:00
description: 本文介绍了 VictoriaMetrics 如何对大数据量的 TSDB 进行快速备份。
draft: true
weight: 4
---

假设你有存储了`TB`级数据的 TSDB 。你如何管理这些数据的备份？你是否认为数据太大而无法备份，并盲目依赖数据库多副本来保证数据安全？那么你就麻烦了。

## 为什么多副本无法完美保证数据可靠性


多副本是指在不同的硬件资源上创建相同数据的多个副本，并保持这些数据的一致性状态。副本可以防止硬件故障，即如果某个节点或磁盘失效，你的数据不应该丢失或损坏，因为至少应该保留一份数据副本。我们安全吗？  
不：
* 如果你在数据库迁移期间意外删除了数据？它会从所有副本中删除。数据丢失了。没有办法恢复它。
* 如果你在例行的数据库集群升级或重新配置期间犯了错误，导致数据丢失？副本在这种情况下也无济于事。

如何防止这些问题？使用传统的备份。

## 传统的备份

有多种数据备份选项，比如附近的 HDD、[磁带](https://en.wikipedia.org/wiki/Magnetic_tape_data_storage)、[专用存储系统](https://en.wikipedia.org/wiki/Network-attached_storage)、[Amazon S3](https://aws.amazon.com/s3/)、[Google Cloud Storage](https://cloud.google.com/storage/) 等。

S3 和 [GCS](https://cloud.google.com/storage/) 是备份最有前途的存储选项。它们价格低廉、可靠且耐用。但它们有一些限制：

* 对上传到对象存储的文件大小有限制：[最大对象大小为 5TB](https://cloud.google.com/storage/quotas#objects) 和[一次上传的最大块大小为 5GB](https://stackoverflow.com/questions/43021266/aws-s3-max-file-size)。如果你需要备份超过这些大小的文件怎么办？
* 网络带宽有限，因此完整备份可能需要几天才能完成。例如，通过千兆网络传输`10TB`数据需要超过`27`小时。
* 网络错误的概率不为零。如果在上传`10TBs`文件的末尾发生网络错误怎么办？再花`27`小时重新上传？
* 从数据库所在的数据中心支付出口流量费用。备份大小和备份频率增加了网络带宽成本。

有没有办法克服这些限制？如果满足某些条件，答案是肯定的：

* 数据必须拆分成多个文件，以便每个文件可以独立备份。
* 文件必须是不可变的，即其内容不应随时间变化。这允许每个文件只上传一次到备份存储。
* 新数据必须进入新文件，因此增量备份可以很便宜——只需备份新文件。
* 文件总数不应太多。这减少了每个文件操作的开销和[管理成本](https://cloud.google.com/storage/pricing#operations-pricing)。
* 数据必须以压缩形式存储在磁盘上，以减少备份期间的网络带宽使用。

如果数据库根据这些条件存储所有数据，那么在 S3 或 GCS 上设置廉价且快速的增量备份就相当容易。通过在旧备份和新备份之间[服务器端复制](https://docs.aws.amazon.com/AmazonS3/latest/dev/CopyingObjectsExamples.html)共享的不可变文件，也可以加快完整备份的速度。GCS 和 S3 都支持服务器端对象复制。当在同一个桶中复制任何大小的对象时，此操作通常很快，因为只复制元数据。

哪种数据结构符合上述原则并可用作 TSDB 的构建块？[B-tree](https://en.wikipedia.org/wiki/B-tree)——大多数数据库的核心？[LMDB](https://en.wikipedia.org/wiki/Lightning_Memory-Mapped_Database)？[PGDATA](https://www.postgresql.org/docs/current/storage-file-layout.html) 或 Postgresql 的 [TOAST](https://wiki.postgresql.org/wiki/TOAST)？

不。这些数据结构都会修改磁盘上的文件内容。

## LSM Tree 和备份
[LSM tree](https://en.wikipedia.org/wiki/Log-structured_merge-tree) 符合上述所有条件：

* 它将数据存储在多个文件中。
* 文件是不可变的。
* 新数据进入新文件。
* 由于后台将较小的文件合并成较大的文件，总文件数保持较低。
* 排序行通常具有良好的压缩比。

LSM 树可以用于构建键值存储，例如 [LevelDB](https://github.com/google/leveldb) 或 [RocksDB](https://github.com/facebook/rocksdb)。这些构建块可以用于创建任意复杂的数据库：

* [CockroachDB](https://www.cockroachlabs.com/docs/stable/architecture/storage-layer.html): 支持 SQL 的大规模分布式数据库。
* [ClickHouse](https://clickhouse.yandex/docs/en/operations/table_engines/mergetree/): 具有类 SQL 语法的快速列式分析数据库。
* [MyRocks](https://en.wikipedia.org/wiki/MyRocks): Facebook 的快速 MySQL 克隆，具有良好的磁盘数据压缩。
* [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/): 快速且经济高效的 TSDB ，具有[最佳磁盘数据压缩](https://medium.com/faun/victoriametrics-achieving-better-compression-for-time-series-data-than-gorilla-317bc1f95932)和[PromQL 支持](https://medium.com/@valyala/promql-tutorial-for-beginners-9ab455142085)。

理论上，如果这些数据库将所有数据存储在类似 LSM 的数据结构中，它们都可以支持增量备份。但是，当新文件不断添加且旧文件不断从数据库中删除时，如何从实时数据中进行备份？由于 LSM 类数据结构中的文件不可变，通过[硬链接](https://en.wikipedia.org/wiki/Hard_link)进行[即时快照](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)然后从快照中备份数据是很容易的。

## 结论
    
* 虽然复制在硬件问题期间提供了可用性，但它不能防止数据丢失。请使用备份。
* 如果使用合适的数据库，大型备份可以快速且廉价。我推荐 [VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/) :)
* VictoriaMetrics 备份可以用于备份从多个 Prometheus 实例收集的数据。