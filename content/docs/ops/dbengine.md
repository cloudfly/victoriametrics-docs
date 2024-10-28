---
title: 存储引擎
date: 2024-10-28T20:28:33+08:00
description: 介绍 VictoriaMetrics 存储引擎相关的一些知识
weight: 30
---


## Storage {#storage}
VictoriaMetrics将接收的数据缓存在内存中，最多一秒钟。然后将缓冲的数据写入`in-memory part`(内存块结构)，之后数据就能被查询了。这些 `in-memory part`定期持久化到磁盘上，避免在发生不正常关闭（如内存崩溃、硬件断电或`SIGKILL`信号）时能够恢复。刷新内存数据到磁盘的时间延时可以通过`-inmemoryDataFlushInterval`启动参数进行配置（请注意，刷新间隔太短可能会显著增加磁盘IO）。

将内存部分持久化到磁盘时，它们被保存在`<-storageDataPath>/data/small/YYYY_MM/`文件夹下的`part`目录中，其中`YYYY_MM`是所保存数据的月份分区。例如，`2022_11`是包含来`自2022年11月`[原始样本]({{< relref "../concepts.md#samples" >}})的部分所属的分区。每个分区目录都包含一个`parts.json`文件，其中列出了该分区中实际存在的部分。

每个`part`目录还包含一个`metadata.json`文件，其中包含以下字段：

+ `RowsCount`- 存储在该`part`中的原始样本数量。
+ `BlocksCount`- 存储在该`part`中的块数量（有关块`part`详细信息请参见下文）。
+ `MinTimestamp`和`MaxTimestamp`- 存储在该`part`中原始样本的最小和最大时间戳。
+ `MinDedupInterval`- 给定的[去重间隔]({{< relref "./cluster.md#deduplidate" >}})。

每个`part`由`block`组成，内部这些`block`按照时间序列ID（也称为`TSID`）排序。每个`block`包含最多`8K`个原始样本，这些样本属于单个时间序列。每个`block`中的原始样本按照时间戳(timestamp)排序。同一时间序列的`block`按第一个样本的时间戳进行排序。所有`block`的时间戳和值以[压缩形式](https://faun.pub/victoriametrics-achieving-better-compression-for-time-series-data-than-gorilla-317bc1f95932)存储在`part`目录下的单独文件中 - `timestamps.bin`和`values.bin`。

`part`目录还包含`index.bin`和`metaindex.bin`文件 - 这些文件包含了快速块查找的索引，这些块属于给定的`TSID`并覆盖给定的时间范围。

`part`会周期性地在后台合并成更大的`part`。后台合并提供以下好处：
+ 保持数据文件数量在控制范围内，以免触发`too many open files`。
+ 提升数据压缩效果，因为通常大`part`比小`part`更容易被压缩。
+ 提升查询速度，因为需要执行检索的`part`更少了，所以更快。
+ 各种后台定时任务都是在合并过程中发生的，比如[去重机制]({{< relref "./cluster.md#deduplidate" >}}), [downsampling](#downsampling) and [释放以删除timeseries的磁盘空间]({{< relref "./single.md#delete-timeseries" >}})

### part 事务保证
新添加的`part`要么成功出现在存储中，要么无法出现。新添加的`part`在完全写入并通过[fsync](https://man7.org/linux/man-pages/man2/fsync.2.html)同步到存储后，会自动注册到相应分区下的`parts.json`文件中。由于这个算法，即使在将`part`写入磁盘过程中发生硬件断电，在下一次 VictoriaMetrics 启动时也会自动删除这些未完全写入的部分，因此存储永远不会包含不完整的`part`。

合并过程也是如此，parts 要么完全合并为一个新的部分，要么无法合并，让原部分保持不变。然而，由于硬件问题，在 VictoriaMetrics 处理过程中可能会出现磁盘故障导致数据损坏。VictoriaMetrics 可以在解压缩、解码或对数据块进行健康检查时检测到损坏。但它无法修复已损坏的数据。启动时加载失败的数据`part`需要被清理或从备份中恢复。因此建议[定期进行备份]({{< relref "./cluster.md#backup" >}})操作。

VictoriaMetrics 在存储数据块时不使用 checksum。请[点击此处](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/3011)了解原因。

VictoriaMetrics 在合并`part`时，如果它们的预期磁盘消耗空间超过了可用磁盘空间，就不会进行合并。这可以防止在合并过程中出现磁盘空间不足的错误。在磁盘空间紧缺的情况下，`part`数量可能会显著增加。这会增加数据查询的开销，因为 VictoriaMetrics 需要从更多的`part`中读取数据来处理每个请求。因此建议使用`-storageDataPath`启动参数指定的目录下至少保留`20%`的可用磁盘空间。

关于合并的处理过程可以参见 [VictoriaMetrics单机监控面板](https://grafana.com/grafana/dashboards/10229-victoriametrics/) 和 [VictoriaMetrics 集群监控面板](https://grafana.com/grafana/dashboards/11176-victoriametrics-cluster/). 更多详情参见[监控文档]({{< relref "./cluster.md#monitoring" >}}).

更多详情可阅读 [这篇文章](https://valyala.medium.com/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)，也可以阅读 [Snapshots 如何工作]({{< relref "./cluster.md#vmstorage-api" >}}).


## IndexDB {#indexdb}
------------------------------------------------------------------------------------

VictoriaMetrics 通过 TSID（时间序列 ID）识别 [timeseries]({{< relref "../concepts.md#timeseries" >}})，并按 TSID 排序存储 [raw sample]({{< relref "../concepts.md#samples" >}})（参见[Storage](#storage)）。因此，TSID 是一个主索引，可以用于搜索和检索 raw sample。然而，TSID 不对客户端暴露，仅供内部使用。

相反，VictoriaMetrics 维护一个倒排索引，通过将这些值映射到相应的 TSID 来实现按指标名、Label 名称和 Label 值搜索 raw sample。

VictoriaMetrics 使用两种类型的倒排索引：
- 全局索引。使用此索引的搜索会在整个数据库里执行。
- 每日索引。此索引存储的内部机制类似于全局索引，只是每个映射中包括了日期信息。这加快短时间范围（通常只是最后一天）查询的数据检索速度。

当执行搜索查询时，VictoriaMetrics 根据查询的时间范围决定使用哪个索引：
- 如果搜索时间范围为`40`天或更短，则使用每日索引。
- 对于时间范围超过`40`天的搜索查询，使用全局索引。

在数据写入期间，映射关系会被添加到 indexdb 中：
- 在全局索引中，每个映射在每个保存时间内只创建一次。
- 在每日索引中，每个映射会为当日出现过的样本的 timeseries 创建一条记录。

IndexDB 遵循保留期限，一旦保留期限到了，索引会被删除。对于新的保留期限，随着新样本的到来，索引将逐渐重新创建。