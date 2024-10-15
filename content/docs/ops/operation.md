---
title: "日常运维"
weight: 20
---

## 如何补写历史数据

具体参考[这里]({{< relref "./single.md#backfilling" >}})

注意，补的数据必须是在`retentionPerid`时间范围内的，如果一个本就是过期的数据写进去，会被直接丢弃。

## 如何对集群版进行扩缩容 {#resize}

1. 在新的机器上启动并运行新的`vmstorage`实例。
2. 为所有 vmselect 组件的`-storageNode`启动参数追加新的`vmstorage`实例地址。
3. 为所有 vminsert 组件的`-storageNode`启动参数追加新的`vmstorage`实例地址。

**上述的`2,3`步骤一定不能反**，如果新 vmstorage 只在 vminsert 里，vmselect 里没有，那么写入到新 vmstorage 实例的数据会被无法查到，直到 vmselect 组件上也追加上这个新实例。

## 有效利用一机多盘 

vminsert 对传输的`-storageNode`地址列表采用一致性 hash 算法进行数据路由。而其多副本的策略，每个`vmstorage`地址，都会将自己的数据赋值给后面相邻的2个`vmstorage`实例。

比如，`-storageNode`的参数值是`a,b,c,d`，而副本数`-replicaFactor`是`2`。那么`a`复制给`b`，`b`复制给`c`，`c`复制给`d`，`d`复制给`a`。这里的复制操作是在 vminsert 里完成的，每个 vmstorage 实例并不感知副本的存在（更多SN架构细节[见文档]({{< relref "./cluster.md#arch" >}})）。

因此我们可以在一个机器上，针对每个磁盘启动一个`vmstorage`实例，同时在`-storageNode`参数中，尽可能让同机器的 vmstorage 不相邻；不相邻的目的是避免一条数据的多个副本，都落在了同一台机器上的 vmstorage 实例上。

## 如何处理机器故障

机器故障的处理分为 2 个步骤，一个是将机器从集群摘除，另一个是在机器修复后加回到集群。后一步可参考[集群扩缩容](#resize)

按照下面的步骤将故障机从集群中摘除：

1. 从所有 vmselect 组件的`-storageNode`启动参数删掉故障的`vmstorage`实例地址。
1. 从所有 vminsert 组件的`-storageNode`启动参数删掉故障的`vmstorage`实例地址。

至于数据备份恢复？如果你设置了多副本，那么大概率是不需要的。

因为故障机上的数据在它的(vminsert的`-storageNode`)相邻地址后面也有一份，而 vmselect 只要能够查到至少一份数据，就能返回正确结果。

## 如何处理磁盘空间不足

磁盘空间属于前期规划的，这种事故主要是因为前期规划失误。只能临时补救。具体有如下集中方法

### 强行 merge
让 vmstorage 执行 merge，会将多个 part merge 成一个 part，减少磁盘空间。有数据持续写入的 partition 会自动触发 merge，不要去强制 merge。所以只对历史 partition 进行 merge。

```shell
## 参数 partition_prefix 指定 partition，partition 的名字在 $DATA/data/small 下可以看到
curl 'http://localhost:8442/internal/force_merge?partition_prefix=2022_01'
```

效果如图所示：

![](disk-usage.png)

磁盘使用率上升是因为 merge 过程创建新的 part 来  merge 老的多个 parts。突然下降代表 merge 结束，删掉老的 parts。

整个 merge 过程，CPU 和 Memory 几乎没有什么影响。merge 的耗时数个小时，跟数据量大小有关。

### 等待
如上所述，系统对多个 part 进行 merge 时，会临时使用一定的磁盘空间，合并后将老的 part 删除就会释放。

因此在磁盘不足时，可查看 vmstorage 是否正在执行 merge，如果是，可以等待其执行完毕。一次 merge 可能会执行是个小时甚至数天。

### 删除 cache
如果 cache 目录比较大，可以删除。但通常不会太大。

### 强制删除历史 partition
删除历史数据是最直接的。

1. 先 stop 掉 vmstorage 组件。
2. 删除 `$DATA/data/{big,small}/YYYY_MM` 目录。
3. 启动 vmstorage。

### 只有一个 partition ?
也就是这一个月而数据磁盘都扛不住，那么只能删除 part。part 的文件夹名称，包含着这个 part 的时间范围。可以根据这些数据删除历史 part。

```plain
./small/2022_02/93109700891_21411093_20220201043320.000_20220204141544.799_16CF806E39D42DF8
```

### 修改 retention
直接修改 vmstorage 的运行参数，让 retention 更短。然后重启，让 vmstorage 自己去删过期的 partition 也是OK的。

不过这就是永久生效了，而不是临时删下历史数据清理磁盘。

### <font style="color:rgb(216,57,49);">不要删 Series</font>
<font style="color:rgb(216,57,49);">因为删除 series 会带来额外很大的开销，让系统不稳定。而且它不会释放多少空间。</font>


## Unexpected query results
--------------------------------------------------------------------------------------------------------------------------

If you see unexpected or unreliable query results from VictoriaMetrics, then try the following steps:

1.  Check whether simplified queries return unexpected results. For example, if the query looks like `sum(rate(http_requests_total[5m])) by (job)`, then check whether the following queries return expected results:
    
    Sometimes the query may be improperly constructed, so it returns unexpected results. It is recommended reading and understanding [MetricsQL docs](https://docs.victoriametrics.com/metricsql/), especially [subqueries](https://docs.victoriametrics.com/metricsql/#subqueries) and [rollup functions](https://docs.victoriametrics.com/metricsql/#rollup-functions) sections.
    

*   Remove the outer `sum` and execute `rate(http_requests_total[5m])`, since aggregations could hide some missing series, gaps in data or anomalies in existing series. If this query returns too many time series, then try adding more specific label filters to it. For example, if you see that the original query returns unexpected results for the `job="foo"`, then use `rate(http_requests_total{job="foo"}[5m])` query. If this isn’t enough, then continue adding more specific label filters, so the resulting query returns manageable number of time series.
    
*   Remove the outer `rate` and execute `http_requests_total`. Additional label filters may be added here in order to reduce the number of returned series.
    

3.  If the simplest query continues returning unexpected / unreliable results, then try verifying correctness of raw unprocessed samples for this query via [/api/v1/export](https://docs.victoriametrics.com/#how-to-export-data-in-json-line-format) on the given `[start..end]` time range and check whether they are expected:
    
    ```
    single-node: curl http://victoriametrics:8428/api/v1/export -d 'match\[\]=http\_requests\_total' -d 'start=...' -d 'end=...' cluster: curl http://<vmselect>:8481/select/<tenantID>/prometheus/api/v1/export -d 'match\[\]=http\_requests\_total' -d 'start=...' -d 'end=...'
    ```
    
    ShellCopy
    
    Note that responses returned from [/api/v1/query](https://docs.victoriametrics.com/keyconcepts/#instant-query) and from [/api/v1/query_range](https://docs.victoriametrics.com/keyconcepts/#range-query) contain evaluated data instead of raw samples stored in VictoriaMetrics. See [these docs](https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness) for details.
    
    If you migrate from InfluxDB, then pass `-search.setLookbackToStep` command-line flag to single-node VictoriaMetrics or to `vmselect` in VictoriaMetrics cluster. See also [how to migrate from InfluxDB to VictoriaMetrics](https://docs.victoriametrics.com/guides/migrate-from-influx.html).
    
4.  Sometimes response caching may lead to unexpected results when samples with older timestamps are ingested into VictoriaMetrics (aka [backfilling](https://docs.victoriametrics.com/#backfilling)). Try disabling response cache and see whether this helps. This can be done in the following ways:
    
    If the problem was in the cache, try resetting it via [resetRollupCache handler](https://docs.victoriametrics.com/url-examples/#internalresetrollupresultcache).
    

*   By passing `-search.disableCache` command-line flag to a single-node VictoriaMetrics or to all the `vmselect` components if cluster version of VictoriaMetrics is used.
    
*   By passing `nocache=1` query arg to every request to `/api/v1/query` and `/api/v1/query_range`. If you use Grafana, then this query arg can be specified in `Custom Query Parameters` field at Prometheus datasource settings - see [these docs](https://grafana.com/docs/grafana/latest/datasources/prometheus/) for details.
    

6.  If you use cluster version of VictoriaMetrics, then it may return partial responses by default when some of `vmstorage` nodes are temporarily unavailable - see [cluster availability docs](https://docs.victoriametrics.com/cluster-victoriametrics/#cluster-availability) for details. If you want to prioritize query consistency over cluster availability, then you can pass `-search.denyPartialResponse` command-line flag to all the `vmselect` nodes. In this case VictoriaMetrics returns an error during querying if at least a single `vmstorage` node is unavailable. Another option is to pass `deny_partial_response=1` query arg to `/api/v1/query` and `/api/v1/query_range`. If you use Grafana, then this query arg can be specified in `Custom Query Parameters` field at Prometheus datasource settings - see [these docs](https://grafana.com/docs/grafana/latest/datasources/prometheus/) for details.
    
7.  If you pass `-replicationFactor` command-line flag to `vmselect`, then it is recommended removing this flag from `vmselect`, since it may lead to incomplete responses when `vmstorage` nodes contain less than `-replicationFactor` copies of the requested data.
    
8.  If you observe gaps when plotting time series try simplifying your query according to p2 and follow the list. If problem still remains, then it is likely caused by irregular intervals for metrics collection (network delays or targets unavailability on scrapes, irregular pushes, irregular timestamps). VictoriaMetrics automatically [fills the gaps](https://docs.victoriametrics.com/keyconcepts/#range-query) based on median interval between [data samples](https://docs.victoriametrics.com/keyconcepts/#raw-samples). This might work incorrect for irregular data as median will be skewed. In this case it is recommended to switch to the static interval for gaps filling by setting `-search.minStalenessInterval=5m` cmd-line flag (`5m` is the static interval used by Prometheus).
    
9.  If you observe recently written data is not immediately visible/queryable, then read more about [query latency](https://docs.victoriametrics.com/keyconcepts/#query-latency) behavior.
    
10.  Try upgrading to the [latest available version of VictoriaMetrics](https://github.com/VictoriaMetrics/VictoriaMetrics/releases/latest) and verifying whether the issue is fixed there.
    
11.  Try executing the query with `trace=1` query arg. This enables query tracing, which may contain useful information on why the query returns unexpected data. See [query tracing docs](https://docs.victoriametrics.com/#query-tracing) for details.
    
12.  Inspect command-line flags passed to VictoriaMetrics components. If you don’t understand clearly the purpose or the effect of some flags, then remove them from the list of flags passed to VictoriaMetrics components, because some command-line flags may change query results in unexpected ways when set to improper values. VictoriaMetrics is optimized for running with default flag values (e.g. when they aren’t set explicitly).
    
13.  If the steps above didn’t help identifying the root cause of unexpected query results, then [file a bugreport](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/new) with details on how to reproduce the issue. Instead of sharing screenshots in the issue, consider sharing query and [trace](https://docs.victoriametrics.com/#query-tracing) results in [VMUI](https://docs.victoriametrics.com/#vmui) by clicking on `Export query` button in top right corner of the graph area.
    

## 数据写入变慢
----------------------------------------------------------------------------------------------------------------

There are the following most commons reasons for slow data ingestion in VictoriaMetrics:

1.  Memory shortage for the given amounts of [active time series](https://docs.victoriametrics.com/faq/#what-is-an-active-time-series).
    
    VictoriaMetrics (or `vmstorage` in cluster version of VictoriaMetrics) maintains an in-memory cache for quick search for internal series ids per each incoming metric. This cache is named `storage/tsid`. VictoriaMetrics automatically determines the maximum size for this cache depending on the available memory on the host where VictoriaMetrics (or `vmstorage`) runs. If the cache size isn’t enough for holding all the entries for active time series, then VictoriaMetrics locates the needed data on disk, unpacks it, re-constructs the missing entry and puts it into the cache. This takes additional CPU time and disk read IO.
    
    The [official Grafana dashboards for VictoriaMetrics](https://docs.victoriametrics.com/#monitoring) contain `Slow inserts` graph, which shows the cache miss percentage for `storage/tsid` cache during data ingestion. If `slow inserts` graph shows values greater than 5% for more than 10 minutes, then it is likely the current number of [active time series](https://docs.victoriametrics.com/faq/#what-is-an-active-time-series) cannot fit the `storage/tsid` cache.
    
    There are the following solutions exist for this issue:
    

*   To increase the available memory on the host where VictoriaMetrics runs until `slow inserts` percentage will become lower than 5%. If you run VictoriaMetrics cluster, then you need increasing total available memory at `vmstorage` nodes. This can be done in two ways: either to increase the available memory per each existing `vmstorage` node or to add more `vmstorage` nodes to the cluster.
    
*   To reduce the number of active time series. The [official Grafana dashboards for VictoriaMetrics](https://docs.victoriametrics.com/#monitoring) contain a graph showing the number of active time series. Recent versions of VictoriaMetrics provide [cardinality explorer](https://docs.victoriametrics.com/#cardinality-explorer), which can help determining and fixing the source of [high cardinality](https://docs.victoriametrics.com/faq/#what-is-high-cardinality).
    

3.  [High churn rate](https://docs.victoriametrics.com/faq/#what-is-high-churn-rate), e.g. when old time series are substituted with new time series at a high rate. When VictoriaMetrics encounters a sample for new time series, it needs to register the time series in the internal index (aka `indexdb`), so it can be quickly located on subsequent select queries. The process of registering new time series in the internal index is an order of magnitude slower than the process of adding new sample to already registered time series. So VictoriaMetrics may work slower than expected under [high churn rate](https://docs.victoriametrics.com/faq/#what-is-high-churn-rate).
    
    The [official Grafana dashboards for VictoriaMetrics](https://docs.victoriametrics.com/#monitoring) provides `Churn rate` graph, which shows the average number of new time series registered during the last 24 hours. If this number exceeds the number of [active time series](https://docs.victoriametrics.com/faq/#what-is-an-active-time-series), then you need to identify and fix the source of [high churn rate](https://docs.victoriametrics.com/faq/#what-is-high-churn-rate). The most commons source of high churn rate is a label, which frequently changes its value. Try avoiding such labels. The [cardinality explorer](https://docs.victoriametrics.com/#cardinality-explorer) can help identifying such labels.
    
4.  Resource shortage. The [official Grafana dashboards for VictoriaMetrics](https://docs.victoriametrics.com/#monitoring) contain `resource usage` graphs, which show memory usage, CPU usage, disk IO usage and free disk size. Make sure VictoriaMetrics has enough free resources for graceful handling of potential spikes in workload according to the following recommendations:
    
    If VictoriaMetrics components have lower amounts of free resources, then this may lead to significant performance degradation after workload increases slightly. For example:
    

*   If the percentage of free CPU is close to 0, then VictoriaMetrics may experience arbitrary long delays during data ingestion when it cannot keep up with slightly increased data ingestion rate.
    
*   If the percentage of free memory reaches 0, then the Operating System where VictoriaMetrics components run, may have no enough memory for [page cache](https://en.wikipedia.org/wiki/Page_cache). VictoriaMetrics relies on page cache for quick queries over recently ingested data. If the operating system has no enough free memory for page cache, then it needs to re-read the requested data from disk. This may significantly increase disk read IO and slow down both queries and data ingestion.
    
*   If free disk space is lower than 20%, then VictoriaMetrics is unable to perform optimal background merge of the incoming data. This leads to increased number of data files on disk, which, in turn, slows down both data ingestion and querying. See [these docs](https://docs.victoriametrics.com/#storage) for details.
    
*   50% of free CPU
    
*   50% of free memory
    
*   20% of free disk space
    

6.  If you run cluster version of VictoriaMetrics, then make sure `vminsert` and `vmstorage` components are located in the same network with small network latency between them. `vminsert` packs incoming data into batch packets and sends them to `vmstorage` on-by-one. It waits until `vmstorage` returns back `ack` response before sending the next packet. If the network latency between `vminsert` and `vmstorage` is high (for example, if they run in different datacenters), then this may become limiting factor for data ingestion speed.
    
    The [official Grafana dashboard for cluster version of VictoriaMetrics](https://docs.victoriametrics.com/cluster-victoriametrics/#monitoring) contain `connection saturation` graph for `vminsert` components. If this graph reaches 100% (1s), then it is likely you have issues with network latency between `vminsert` and `vmstorage`. Another possible issue for 100% connection saturation between `vminsert` and `vmstorage` is resource shortage at `vmstorage` nodes. In this case you need to increase amounts of available resources (CPU, RAM, disk IO) at `vmstorage` nodes or to add more `vmstorage` nodes to the cluster.
    
7.  Noisy neighbor. Make sure VictoriaMetrics components run in an environments without other resource-hungry apps. Such apps may steal RAM, CPU, disk IO and network bandwidth, which is needed for VictoriaMetrics components. Issues like this are very hard to catch via [official Grafana dashboard for cluster version of VictoriaMetrics](https://docs.victoriametrics.com/cluster-victoriametrics/#monitoring) and proper diagnosis would require checking resource usage on the instances where VictoriaMetrics runs.
    
8.  If you see `TooHighSlowInsertsRate` [alert](https://docs.victoriametrics.com/#monitoring) when single-node VictoriaMetrics or `vmstorage` has enough free CPU and RAM, then increase `-cacheExpireDuration` command-line flag at single-node VictoriaMetrics or at `vmstorage` to the value, which exceeds the interval between ingested samples for the same time series (aka `scrape_interval`). See [this comment](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/3976#issuecomment-1476883183) for more details.
    
9.  If you see constant and abnormally high CPU usage of VictoriaMetrics component, check `CPU spent on GC` panel on the corresponding [Grafana dashboard](https://grafana.com/orgs/victoriametrics) in `Resource usage` section. If percentage of CPU time spent on garbage collection is high, then CPU usage of the component can be reduced at the cost of higher memory usage by changing [GOGC](https://tip.golang.org/doc/gc-guide#GOGC) environment variable to higher values. By default VictoriaMetrics components use `GOGC=30`. Try running VictoriaMetrics components with `GOGC=100` and see whether this helps reducing CPU usage. Note that higher `GOGC` values may increase memory usage.
    

## 慢查询

Some queries may take more time and resources (CPU, RAM, network bandwidth) than others. VictoriaMetrics logs slow queries if their execution time exceeds the duration passed to `-search.logSlowQueryDuration` command-line flag (5s by default).

VictoriaMetrics provides [`top queries` page at VMUI](https://docs.victoriametrics.com/#top-queries), which shows queries that took the most time to execute.

There are the following solutions exist for improving performance of slow queries:

*   Adding more CPU and memory to VictoriaMetrics, so it may perform the slow query faster. If you use cluster version of VictoriaMetrics, then migrating `vmselect` nodes to machines with more CPU and RAM should help improving speed for slow queries. Query performance is always limited by resources of one `vmselect` which processes the query. For example, if 2vCPU cores on `vmselect` isn’t enough to process query fast enough, then migrating `vmselect` to a machine with 4vCPU cores should increase heavy query performance by up to 2x. If the line on `concurrent select` graph form the [official Grafana dashboard for VictoriaMetrics](https://docs.victoriametrics.com/cluster-victoriametrics/#monitoring) is close to the limit, then prefer adding more `vmselect` nodes to the cluster. Sometimes adding more `vmstorage` nodes also can help improving the speed for slow queries.
    
*   Rewriting slow queries, so they become faster. Unfortunately it is hard determining whether the given query is slow by just looking at it.
    
    The main source of slow queries in practice is [alerting and recording rules](https://docs.victoriametrics.com/vmalert/#rules) with long lookbehind windows in square brackets. These queries are frequently used in SLI/SLO calculations such as [Sloth](https://github.com/slok/sloth).
    
    For example, `avg_over_time(up[30d]) > 0.99` needs to read and process all the [raw samples](https://docs.victoriametrics.com/keyconcepts/#raw-samples) for `up` [time series](https://docs.victoriametrics.com/keyconcepts/#time-series) over the last 30 days each time it executes. If this query is executed frequently, then it can take significant share of CPU, disk read IO, network bandwidth and RAM. Such queries can be optimized in the following ways:
    
    Another source of slow queries is improper use of [subqueries](https://docs.victoriametrics.com/metricsql/#subqueries). It is recommended avoiding subqueries if you don’t understand clearly how they work. It is easy to create a subquery without knowing about it. For example, `rate(sum(some_metric))` is implicitly transformed into the following subquery according to [implicit conversion rules for MetricsQL queries](https://docs.victoriametrics.com/metricsql/#implicit-query-conversions):
    
    ```
    rate(   sum(     default\_rollup(some\_metric\[1i\])   )\[1i:1i\] )
    ```
    
    MetricsQLCopy
    
    It is likely this query won’t return the expected results. Instead, `sum(rate(some_metric))` must be used instead. See [this article](https://www.robustperception.io/rate-then-sum-never-sum-then-rate/) for more details.
    
    VictoriaMetrics provides [query tracing](https://docs.victoriametrics.com/#query-tracing) feature, which can help determining the source of slow query. See also [this article](https://valyala.medium.com/how-to-optimize-promql-and-metricsql-queries-85a1b75bf986), which explains how to determine and optimize slow queries.
    

*   To reduce the lookbehind window in square brackets. For example, `avg_over_time(up[10d])` takes up to 3x less compute resources than `avg_over_time(up[30d])` at VictoriaMetrics.
    
*   To increase evaluation interval for alerting and recording rules, so they are executed less frequently. For example, increasing `-evaluationInterval` command-line flag value at [vmalert](https://docs.victoriametrics.com/vmalert/) from `1m` to `2m` should reduce compute resource usage at VictoriaMetrics by 2x.
    

## Out of memory 错误

There are the following most common sources of out of memory (aka OOM) crashes in VictoriaMetrics:

1.  Improper command-line flag values. Inspect command-line flags passed to VictoriaMetrics components. If you don’t understand clearly the purpose or the effect of some flags - remove them from the list of flags passed to VictoriaMetrics components. Improper command-line flags values may lead to increased memory and CPU usage. The increased memory usage increases chances for OOM crashes. VictoriaMetrics is optimized for running with default flag values (e.g. when they aren’t set explicitly).
    
    For example, it isn’t recommended tuning cache sizes in VictoriaMetrics, since it frequently leads to OOM exceptions. [These docs](https://docs.victoriametrics.com/#cache-tuning) refer command-line flags, which aren’t recommended to tune. If you see that VictoriaMetrics needs increasing some cache sizes for the current workload, then it is better migrating to a host with more memory instead of trying to tune cache sizes manually.
    
2.  Unexpected heavy queries. The query is considered as heavy if it needs to select and process millions of unique time series. Such query may lead to OOM exception, since VictoriaMetrics needs to keep some of per-series data in memory. VictoriaMetrics provides [various settings](https://docs.victoriametrics.com/#resource-usage-limits), which can help limit resource usage. For more context, see [How to optimize PromQL and MetricsQL queries](https://valyala.medium.com/how-to-optimize-promql-and-metricsql-queries-85a1b75bf986). VictoriaMetrics also provides [query tracer](https://docs.victoriametrics.com/#query-tracing) to help identify the source of heavy query.
    
3.  Lack of free memory for processing workload spikes. If VictoriaMetrics components use almost all the available memory under the current workload, then it is recommended migrating to a host with bigger amounts of memory. This would protect from possible OOM crashes on workload spikes. It is recommended to have at least 50% of free memory for graceful handling of possible workload spikes. See [capacity planning for single-node VictoriaMetrics](https://docs.victoriametrics.com/#capacity-planning) and [capacity planning for cluster version of VictoriaMetrics](https://docs.victoriametrics.com/cluster-victoriametrics/#capacity-planning).
    

## Cluster instability

VictoriaMetrics cluster may become unstable if there is no enough free resources (CPU, RAM, disk IO, network bandwidth) for processing the current workload.

The most common sources of cluster instability are:

*   Workload spikes. For example, if the number of active time series increases by 2x while the cluster has no enough free resources for processing the increased workload, then it may become unstable. VictoriaMetrics provides various configuration settings, which can be used for limiting unexpected workload spikes. See [these docs](https://docs.victoriametrics.com/cluster-victoriametrics/#resource-usage-limits) for details.
    
*   Various maintenance tasks such as rolling upgrades or rolling restarts during configuration changes. For example, if a cluster contains `N=3` `vmstorage` nodes and they are restarted one-by-one (aka rolling restart), then the cluster will have only `N-1=2` healthy `vmstorage` nodes during the rolling restart. This means that the load on healthy `vmstorage` nodes increases by at least `100%/(N-1)=50%` comparing to the load before rolling restart. E.g. they need to process 50% more incoming data and to return 50% more data during queries. In reality, the load on the remaining `vmstorage` nodes increases even more because they need to register new time series, which were re-routed from temporarily unavailable `vmstorage` node. If `vmstorage` nodes had less than 50% of free resources (CPU, RAM, disk IO) before the rolling restart, then it can lead to cluster overload and instability for both data ingestion and querying.
    
    The workload increase during rolling restart can be reduced by increasing the number of `vmstorage` nodes in the cluster. For example, if VictoriaMetrics cluster contains `N=11` `vmstorage` nodes, then the workload increase during rolling restart of `vmstorage` nodes would be `100%/(N-1)=10%`. It is recommended to have at least 8 `vmstorage` nodes in the cluster. The recommended number of `vmstorage` nodes should be multiplied by `-replicationFactor` if replication is enabled - see [replication and data safety docs](https://docs.victoriametrics.com/cluster-victoriametrics/#replication-and-data-safety) for details.
    
*   Time series sharding. Received time series [are consistently sharded](https://docs.victoriametrics.com/cluster-victoriametrics/#architecture-overview) by `vminsert` between configured `vmstorage` nodes. As a sharding key `vminsert` is using time series name and labels, respecting their order. If the order of labels in time series is constantly changing, this could cause wrong sharding calculation and result in un-even and sub-optimal time series distribution across available vmstorages. It is expected that metrics pushing client is responsible for consistent labels order (like `Prometheus` or `vmagent` during scraping). If this can’t be guaranteed, set `-sortLabels=true` cmd-line flag to `vminsert`. Please note, sorting may increase CPU usage for `vminsert`.
    

The obvious solution against VictoriaMetrics cluster instability is to make sure cluster components have enough free resources for graceful processing of the increased workload. See [capacity planning docs](https://docs.victoriametrics.com/cluster-victoriametrics/#capacity-planning) and [cluster resizing and scalability docs](https://docs.victoriametrics.com/cluster-victoriametrics/#cluster-resizing-and-scalability) for details.

## 磁盘空间不够用

If too much disk space is used by a [single-node VictoriaMetrics](https://docs.victoriametrics.com/) or by `vmstorage` component at [VictoriaMetrics cluster](https://docs.victoriametrics.com/cluster-victoriametrics/), then please check the following:

*   Make sure that there are no old snapsots, since they can occupy disk space. See [how to work with snapshots](https://docs.victoriametrics.com/#how-to-work-with-snapshots) and [snapshot troubleshooting](https://docs.victoriametrics.com/#snapshot-troubleshooting).
    
*   Under normal conditions the size of `<-storageDataPath>/indexdb` folder must be smaller than the size of `<-storageDataPath>/data` folder, where `-storageDataPath` is the corresponding command-line flag value. This can be checked by the following query if [VictoriaMetrics monitoring](https://docs.victoriametrics.com/troubleshooting/?highlight=trouble#monitoring) is properly set up:
    
    ```
    sum(vm\_data\_size\_bytes{type=~"indexdb/.+"}) without(type)   / sum(vm\_data\_size\_bytes{type=~"(storage|indexdb)/.+"}) without(type)
    ```
    
    MetricsQLCopy
    
    If this query returns values bigger than 0.5, then it is likely there is a [high churn rate](https://docs.victoriametrics.com/faq/#what-is-high-churn-rate) issue, which results in excess disk space usage for both `indexdb` and `data` folders under `-storageDataPath` folder. The solution is to identify and fix the source of high churn rate with [cardinality explorer](https://docs.victoriametrics.com/#cardinality-explorer).
    
