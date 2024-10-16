---
title: 存储引擎
description: 介绍 VictoriaMetrics 存储引擎相关的一些知识
weight: 30
---


## Storage {#storage}
VictoriaMetrics将接收的数据缓存在内存中，最多一秒钟。然后将缓冲的数据写入内存部分，在查询期间可以进行搜索。这些in-memory `part`定期持久化到磁盘上，以便在发生不正常关闭（如内存崩溃、硬件断电或`SIGKILL`信号）时能够恢复。刷新内存数据到磁盘的时间间隔可以通过`-inmemoryDataFlushInterval`启动参数进行配置（请注意，过短的刷新间隔可能会显著增加磁盘IO）。

将内存部分持久化到磁盘时，它们被保存在`<-storageDataPath>/data/small/YYYY_MM/`文件夹下的`part`目录中，其中`YYYY_MM`是所保存数据的月份分区。例如，`2022_11`是包含来`自2022年11月`[原始样本]({{< relref "../concepts.md#samples" >}})的部分所属的分区。每个分区目录都包含一个`parts.json`文件，其中列出了该分区中实际存在的部分。

每个`part`目录还包含一个`metadata.json`文件，其中包含以下字段：

+ `RowsCount`- 存储在零件中的原始样本数量。
+ `BlocksCount`- 存储在该部分中的块数量（有关块的详细信息请参见下文）。
+ `MinTimestamp`和`MaxTimestamp`- 存储在该部分中原始样本的最小和最大时间戳。
+ `MinTimestamp`and `MaxTimestamp`- minimum and maximum timestamps across raw samples stored in the part
+ `MinDedupInterval`- 给定部分应用的[去重间隔]({{< relref "./cluster.md#deduplidate" >}})。

每个 part 由按内部时间序列ID（也称为`TSID`）排序的`block`组成。每个`block`包含最多`8K`个原始样本，这些样本属于单个时间序列。每个`block`中的原始样本按照时间戳进行排序。同一时间序列的块按第一个样本的时间戳进行排序。所有块的时间戳和值以[压缩形式](https://faun.pub/victoriametrics-achieving-better-compression-for-time-series-data-than-gorilla-317bc1f95932)存储在`part`目录下的单独文件中 - `timestamps.bin`和`values.bin`。

`part`目录还包含`index.bin`和`metaindex.bin`文件 - 这些文件包含了快速块查找的索引，这些块属于给定的`TSID`并覆盖给定的时间范围。

部分会周期性地在后台合并成更大的part。后台合并提供以下好处：

+ 保持数据文件数量在控制范围内，以免超过打开文件的限制。
+ 改进的数据压缩，因为通常较大的部分比较小的部分更容易被压缩。
+ 查询速度提升了，因为对较少部分的查询执行更快。
+ 各种后台维护任务都是在合并过程中发生的，比如[去重机制]({{< relref "./cluster.md#deduplidate" >}}), [downsampling](#downsampling) and [释放以删除timeseries的磁盘空间](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-delete-time-series)

新添加的 part 要么成功出现在存储中，要么无法出现。新添加的 part 在完全写入并通过[fsync](https://man7.org/linux/man-pages/man2/fsync.2.html)同步到存储后，会自动注册到相应分区下的`parts.json`文件中。由于这个算法，即使在将part写入磁盘过程中发生硬件断电，在下一次VictoriaMetrics启动时也会自动删除这些未完全写入的部分，因此存储永远不会包含部分创建的part。

合并过程也是如此——parts 要么完全合并为一个新的部分，要么无法合并，使得源部分保持不变。然而，由于硬件问题，在VictoriaMetrics处理过程中可能会导致磁盘上的数据损坏。VictoriaMetrics可以在解压缩、解码或对数据块进行健康检查时检测到损坏。但它无法修复已损坏的数据。启动时加载失败的数据部分需要被删除或从备份中恢复。因此建议[定期进行备份]({{< relref "./cluster.md#backup" >}})操作。

VictoriaMetrics在存储数据块时不使用校验和。请[点击此处](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/3011)了解原因。

VictoriaMetrics在合并部分时，如果它们的摘要大小超过了可用磁盘空间，则不会进行合并。这样可以防止在合并过程中出现磁盘空间不足的错误。在磁盘空间紧缺的情况下，部分数量可能会显著增加。这会增加数据查询时的开销，因为VictoriaMetrics需要从更多的部分中读取数据来处理每个请求。因此建议使用`-storageDataPath`启动参数指定的目录下至少保留20% 的可用磁盘空间。

关于合并的处理过程可以参见 [the dashboard for single-node VictoriaMetrics](https://grafana.com/grafana/dashboards/10229-victoriametrics/) 和 [the dashboard for VictoriaMetrics cluster](https://grafana.com/grafana/dashboards/11176-victoriametrics-cluster/). 更多详情参见[监控文档]({{< relref "./cluster.md#monitoring" >}}).

更多详情可阅读 [这篇文章](https://valyala.medium.com/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)，也可以阅读 [how to work with snapshots](./cluster.md#vmstorage-api接口).


## IndexDB {#indexdb}
------------------------------------------------------------------------------------

VictoriaMetrics identifies [time series]({{< relref "../concepts.md#timeseries" >}}) by `TSID` (time series ID) and stores [raw samples]({{< relref "../concepts.md#samples" >}}) sorted by TSID (see [Storage](#storage)). Thus, the TSID is a primary index and could be used for searching and retrieving raw samples. However, the TSID is never exposed to the clients, i.e. it is for internal use only.

Instead, VictoriaMetrics maintains an inverted index that enables searching the raw samples by metric name, label name, and label value by mapping these values to the corresponding TSIDs.

VictoriaMetrics uses two types of inverted indexes:

*   Global index. Searches using this index is performed across the entire retention period.
    
*   Per-day index. This index stores mappings similar to ones in global index but also includes the date in each mapping. This speeds up data retrieval for queries within a shorter time range (which is often just the last day).
    

When the search query is executed, VictoriaMetrics decides which index to use based on the time range of the query:

*   Per-day index is used if the search time range is 40 days or less.
    
*   Global index is used for search queries with a time range greater than 40 days.
    

Mappings are added to the indexes during the data ingestion:

*   In global index each mapping is created only once per retention period.
    
*   In the per-day index each mapping is be created for each unique date that has been seen in the samples for the corresponding time series.
    

IndexDB respects [retention period]({{< relref "./single.md#retention" >}}) and once it is over, the indexes are dropped. For the new retention period, the indexes are gradually populated again as the new samples arrive.

## Cache removal {#cache-removal}

VictoriaMetrics uses various internal caches. These caches are stored to `<-storageDataPath>/cache` directory during graceful shutdown (e.g. when VictoriaMetrics is stopped by sending `SIGINT` signal). The caches are read on the next VictoriaMetrics startup. Sometimes it is needed to remove such caches on the next startup. This can be done in the following ways:

*   By manually removing the `<-storageDataPath>/cache` directory when VictoriaMetrics is stopped.
    
*   By placing `reset_cache_on_startup` file inside the `<-storageDataPath>/cache` directory before the restart of VictoriaMetrics. In this case VictoriaMetrics will automatically remove all the caches on the next start. See [this issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1447) for details.
    

It is also possible removing [rollup result cache](#cache-rollup) on startup by passing `-search.resetRollupResultCacheOnStartup` command-line flag to VictoriaMetrics.

## Rollup result cache {#cache-rollup}

VictoriaMetrics caches query responses by default. This allows increasing performance for repeated queries to [`/api/v1/query`]({{< relref "../query/_index.md#instant-query" >}}) and [`/api/v1/query_range`]({{< relref "../query/_index.md#range-query" >}}) with the increasing `time`, `start` and `end` query args.

This cache may work incorrectly when ingesting historical data into VictoriaMetrics. See [these docs](https://docs.victoriametrics.com/single-server-victoriametrics/#backfilling) for details.

The rollup cache can be disabled either globally by running VictoriaMetrics with `-search.disableCache` command-line flag or on a per-query basis by passing `nocache=1` query arg to `/api/v1/query` and `/api/v1/query_range`.

See also [cache removal docs](#cache-removal).

## Cache tuning {#cache-tuning}

VictoriaMetrics uses various in-memory caches for faster data ingestion and query performance. The following metrics for each type of cache are exported at [`/metrics` page](https://docs.victoriametrics.com/single-server-victoriametrics/#monitoring):

*   `vm_cache_size_bytes` \- the actual cache size
    
*   `vm_cache_size_max_bytes` \- cache size limit
    
*   `vm_cache_requests_total` \- the number of requests to the cache
    
*   `vm_cache_misses_total` \- the number of cache misses
    
*   `vm_cache_entries` \- the number of entries in the cache
    

Both Grafana dashboards for [single-node VictoriaMetrics](https://grafana.com/grafana/dashboards/10229) and [clustered VictoriaMetrics](https://grafana.com/grafana/dashboards/11176) contain `Caches` section with cache metrics visualized. The panels show the current memory usage by each type of cache, and also a cache hit rate. If hit rate is close to 100% then cache efficiency is already very high and does not need any tuning. The panel `Cache usage %` in `Troubleshooting` section shows the percentage of used cache size from the allowed size by type. If the percentage is below 100%, then no further tuning needed.

Please note, default cache sizes were carefully adjusted accordingly to the most practical scenarios and workloads. Change the defaults only if you understand the implications and vmstorage has enough free memory to accommodate new cache sizes.

To override the default values see command-line flags with `-storage.cacheSize` prefix. See the full description of flags [here](https://docs.victoriametrics.com/single-server-victoriametrics/#list-of-command-line-flags).