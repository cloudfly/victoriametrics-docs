---
title: 单机版本
description: VictoriaMetrics 单机版本的相关功能介绍。主要包含 VictoriaMetrics 的通用存储能力，比如保存时间、备份、去重机制等等
weight: 5
---


## 服务(组件)运维

### 容量规划 {#capacity}

VictoriaMetrics 在我们的[案例研究](https://docs.victoriametrics.com/CaseStudies.html)中表明，与其他解决方案（Prometheus、Thanos、Cortex、TimescaleDB、InfluxDB、QuestDB和M3DB）相比，在生产环境对CPU、RAM和存储空间的资源消耗都更少。

VictoriaMetrics 的容量与可用资源呈线性关系。所需的 CPU 和 RAM 数量高度依赖于数据量 - [活跃时间序列]({{< relref "../faq.md#what-is-an-active-time-series" >}})的数量、指标[替换率]({{< relref "../faq.md#what-is-high-churn-rate" >}})、查询类型、查询每秒请求数等等。建议根据[故障排除](#troubleshooting)文档，为您的生产数据搭建一个测试 VictoriaMetrics，并反复地调整 CPU 和 RAM 资源，直到其稳定运行。根据我们的[案例研究](https://docs.victoriametrics.com/CaseStudies.html)，单机版 VictoriaMetrics 可以完美地处理以下生产数据量：

+ 写入速率: 150万/秒+ 的样本数。
+ 活跃 time series 总量: 5000万+
+ time series 总量: 50亿+
+ Time series 替换率: 每天1.5亿+
+ 样本总数: 10万亿
+ 查询：200+ qps
+ 查询延时 (P99): 1 second

根据测试运行期间的磁盘空间使用情况，可以推算出所需的存储空间（保存时间通过`-retentionPeriod`启动参数设置）。例如，如果在生产环境上进行了为期一天的测试运行后，`-storageDataPath`目录大小变为`10GB`，则对于`-retentionPeriod=100d`（100天保存时间），至少需要`10GB*100=1TB`的磁盘空间。

建议保留以下数量的备用资源：

+ 为了降低突发流量峰值期间，内存溢出（OOM）导致系统崩溃和减速的概率，建议保留`50%`的空闲 RAM。
+ 为了降低突发流量期间，系统性能降低的可能性，将`50%`的空闲 CPU 用于分配。
+ 至少保留`-storageDataPath`启动参数指定的目录中 [20% 的可用存储空间](#storage)。详见[此处](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#list-of-command-line-flags)`-storage.minFreeDiskSpaceBytes`启动参数说明。

参见[资源使用限制](#limitation)。

### 保存时间(期限) {#retention}

保留期是通过`-retentionPeriod`启动参数指定的，该参数后面跟着一个数字和时间单位字符 - `h`(小时),`d`(天),`w`(周),`y`(年)。如果未指定时间单位，则默认为**月份**。例如，`-retentionPeriod=3`表示数据将被存储`3`个月然后删除。**默认的保留期为一个月**。最小的保留期为`24`小时或者`1`天。

数据被分割成每月的分区(`partition`)，存储在`<-storageDataPath>/data/{small,big}`文件夹中。每个分区由一个或多个`part`组成。

**超出保存期限的数据分区会在新月份的第一天被删除。超出配置保存期限的`part`最终会在后台合并过程中删除。**

`part`所覆盖的时间范围不受保存期限限制。一个数据`part`可以涵盖几小时或几天的数据。因此，只有当完全超出配置保留期时才能删除一个`part`。

给定的保留期（`-retentionPeriod`）对应的最大磁盘空间使用量将是`-retentionPeriod`+ 1 个月。例如，如果`-retentionPeriod`设置为`1`，则一月份的数据将在3月1日被删除。

在现有数据上延长保留期是安全的。如果将保留期（`-retentionPeriod`）设置为比之前更低的值，则超过保存时间外的数据最终将被删除。

VictoriaMetrics不支持无限保存时间，但您可以指定一个任意长的持续时间，例如`-retentionPeriod=100y`。

### 资源使用限制 {#limitation}

默认情况下，VictoriaMetrics 针对典型业务场景进行了优化，以最大化利用资源。某些业务场景可能需要细粒度的资源使用限制。在这些情况下，以下启动参数可能会有用：

+ `-memory.allowedPercent`和`-memory.allowedBytes`：限制 VictoriaMetrics 内部缓存使用的内存大小。请注意，VictoriaMetrics 可能会使用更多的内存，因为这些参数不限制每个查询执行时所需的额外内存。
+ `-search.maxMemoryPerQuery`：限制用于处理单个查询的内存用量。需要更多内存的查询将被拒绝。查询大量数据的重查询可能会略微超过每个查询的内存限制。并行的查询的总内存限制可以估计为`-search.maxMemoryPerQuery * -search.maxConcurrentRequests`。
+ `-search.maxUniqueTimeseries`：限制单次查询允许检索并处理的唯一时间序列的数量。VictoriaMetrics 在内存中保留有关每个查询检索到的时间序列的一些元信息，并花费一些CPU时间来处理检索的时间序列。这意味着单个查询可以使用的最大内存使用量和CPU使用量与`-search.maxUniqueTimeseries`成比例。
+ `-search.maxQueryDuration`：限制单个查询的最大执行时间。如果查询超过给定的时间，就会取消。这可以避免意外的重度查询对CPU和内存过度消耗。
+ `-search.maxConcurrentRequests`：限制 VictoriaMetrics 可以处理的并发请求数量。更多的并发请求通常意味着更大的内存使用量。例如，如果单个查询在执行过程中需要`100 MiB`的额外内存，则`100`个并发查询可能就需要`100 * 100 MiB = 10 GiB`的额外内存。因此，在达到并发限制时，最好限制并发查询的数量，并让新进来的查询请求排队。VictoriaMetrics提供了`-search.maxQueueDuration`启动参数来限制查询排队的最长等待时间。另请参阅`-search.maxMemoryPerQuery`启动参数。
+ `-search.maxSamplesPerSeries`：每个查询可以处理的原始样本数量。VictoriaMetrics 在查询期间按顺序处理每个检索的时间序列的原始样本。它将所选时间范围内每个原始样本解压缩到内存中，然后应用给定的[Rullup函数]({{< relref "../query/metricsql/functions/rollup.md" >}})。当查询在包含数亿条原始样本需要计算时，`-search.maxSamplesPerSeries`启动参数可以限制它对内存的消耗。
+ `-search.maxSamplesPerQuery`：限制单个查询可以处理的原始样本数量。这样可以限制重查询的CPU使用率，`-search.maxSamplesPerSeries`限制的是每个 timeseries，该参数限制的是一个查询中所有 timeseries 的原始样本总量。
+ `-search.maxPointsPerTimeseries`：限制每个[Range Query]({{< relref "../query/_index.md#range-query" >}})返回的数据点数。
+ `-search.maxPointsSubqueryPerTimeseries`：限制在子查询评估过程中，每个子查询语句结果中的数据点总数。
+ `-search.maxSeriesPerAggrFunc`限制在单个查询中由[MetricsQL聚合函数]({{< relref "../query/metricsql/functions/aggregation.md" >}})生成的时间序列数量。
+ `-search.maxSeries`限制从[/api/v1/series]({{< relref "../query/api.md#apiv1series" >}})返回的时间序列数量。这个接口主要被 Grafana 用于实现 Metric 名称、Label 名称和 Label 值的自动提示。当数据库包含大量唯一时间序列时，对该接口的查询可能会消耗大量的CPU时间和内存，因为存在[高频率变化]({{< relref "../faq.md#what-is-high-churn-rate" >}})。在这种情况下，将`-search.maxSeries`设置为较低的值有助于限制CPU和内存使用。
+ `-search.maxTagKeys`限制从[/api/v1/labels]({{< relref "../query/api.md#apiv1labels" >}})返回的项目数量。此接口主要用于 Grafana 自动实现 Label 名称提示。当数据库包含大量唯一时间序列时，对此接口的查询可能会消耗大量的CPU时间和内存，因为存在[高频率变化]({{< relref "../faq.md#what-is-high-churn-rate" >}})。在这种情况下，将`-search.maxTagKeys`设置为较低值有助于限制CPU和内存使用。
+ `-search.maxTagValues`限制从[/api/v1/label/.../values]({{< relref "../query/api.md#apiv1labelnamevalues" >}})返回的项目数量。此接口主要用于 Grafana 实现自动提示 Label 值。由于[高频率更改]({{< relref "../faq.md#what-is-high-churn-rate" >}})，当数据库包含大量唯一时间序列时，对该接口的查询可能会消耗大量CPU时间和内存。在这种情况下，将`-search.maxTagValues`设置为较低的值有助于限制CPU和内存使用。
+ `-search.maxTagValueSuffixesPerSearch`限制了从`/metrics/find`端点返回的条目数量。请参阅[Graphite Metrics API使用文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-metrics-api-usage)。

参见 [基数限制](#cardinality) and [容量规划](#capacity).

### 高可用 {#high-available}

#### 数据双发

+ 在不同的数据中心（available zone）安装多个 VictoriaMetrics 实例。
+ 将这些实例的地址通过`-remoteWrite.url`启动参数传递给 [vmagent](https://docs.victoriametrics.com/vmagent.html)。


```sh
/path/to/vmagent -remoteWrite.url=http://<victoriametrics-addr-1>:8428/api/v1/write -remoteWrite.url=http://<victoriametrics-addr-2>:8428/api/v1/write
```

或者这些地址可以传递给Prometheus配置中的`remote_write`部分：


```yaml
remote_write:
  - url: http://<victoriametrics-addr-1>:8428/api/v1/write
    queue_config:
      max_samples_per_send: 10000
  # ...
  - url: http://<victoriametrics-addr-N>:8428/api/v1/write
    queue_config:
      max_samples_per_send: 10000
```

+ 应用更新的配置：

```sh
kill -HUP `pidof prometheus`
```

#### 配置查询代理

+ 现在Prometheus应该并行地将数据写入所有配置的`remote_write`URL。
+ 在所有的 VictoriaMetrics 副本前面设置[Proxy](https://github.com/jacksontj/promxy)。
+ 在 Grafana 中设置一个指向 Proxy 的 Prometheus 数据源。

#### 关于数据重复
如果您的 Prometheus 本身也是多副本的，比如 2 个完全一样的 Prometheus（`r1`和`r2`） 做一模一样的事。那么请将每个`r1`配置为将数据写入`victoriametrics-addr-1`，而每个`r2`应该将数据写入`victoriametrics-addr-2`。

当然你也可以让`r1`和`r2`的 remote write 配置完全一样，二者都是双发的，VictoriaMetrics 会自动对相同的数据进行去重。有关详细信息请参阅[此部分](#deduplicate)。

### 监控 {#metrics}
VictoriaMetrics在`/metrics`页面以Prometheus公开格式导出内部指标。这些指标可以通过[vmagent](https://docs.victoriametrics.com/vmagent.html)或Prometheus进行抓取。另外，当`-selfScrapeInterval`启动参数设置为大于0的持续时间时，单机版的VictoriaMetrics可以自动抓取指标。例如，`-selfScrapeInterval=10s`将启用每10秒一次的自动抓取`/metrics`页面。

官方提供了适用于[单机版](https://grafana.com/grafana/dashboards/10229-victoriametrics/)和[集群版](https://grafana.com/grafana/dashboards/11176-victoriametrics-cluster/) VictoriaMetrics 的 Grafana 仪表板。还可以查看由社区创建的适用于[集群 VictoriaMetrics 的替代仪表板](https://grafana.com/grafana/dashboards/11831)。

仪表板上的图表包含有用的提示 - 将鼠标悬停在每个图表左上角的`i`图标上以阅读它。

我们建议通过[vmalert]({{< relref "../components/vmalert.md" >}})或Prometheus设置警报。

VictoriaMetrics 在`/api/v1/status/active_queries`接口中展示当前正在执行的查询以及它们的运行时间。在`/api/v1/status/top_queries`接口展示执行时间最长的查询语句。

参见 [VictoriaMetrics Monitoring](https://victoriametrics.com/blog/victoriametrics-monitoring/) 和 [问题排查]({{< relref "./operation.md#troubleshooting" >}}).

#### Push Metrics
所有的 VictoriaMetrics 组件支持将`/metrics`页面上开放指标以 Prometheus 文本格式推送到其他地方。如果 VictoriaMetrics 组件位于隔离网络中，无法被本地[vmagent]({{< relref "../components//vmagent.md" >}})抓取，则可以使用此功能来替代[经典的类Prometheus指标抓取](https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter)。

以下启动参数与从 VictoriaMetrics 组件推送指标相关：

+ `-pushmetrics.url`: Push 的目标 URL 地址。比如， `-pushmetrics.url=http://victoria-metrics:8428/api/v1/import/prometheus`表示把内部指标 Push 到`/api/v1/import/prometheus`中，参见[这个文档]({{< relref "../write/api.md#prometheus" >}})。 `-pushmetrics.url`参数可以被指定多次。这种情况下 metrics 会被 Push 到所有目标 URL 地址上。URL 中也可以包含上 Basic Auth 信息，格式是`http://user:pass@hostname/api/v1/import/prometheus`。Metrics 是以压缩的形式被 Push 到`-pushmetrics.url`中的，请求头中带有`Content-Encoding: gzip`。这可以减少 Push 所需的网络带宽。
+ `-pushmetrics.extraLabel`- 在把 metrics 数据 Push 到`-pushmetrics.url`之前追加一些 Label 。每一个Label都是用`label="value"`的格式指定。启动参数`-pushmetrics.extraLabel`也是可以被多次指定的。这种情况下会将指定的多个Label 全都追加到 metrics 数据中，再 Push 给`-pushmetrics.url`地址。
+ `-pushmetrics.interval`- Push 动作的间隔，默认是 10 秒一次。

例如，以下命令指示 VictoriaMetrics 将`/metrics`里的指标推送到`https://maas.victoriametrics.com/api/v1/import/prometheus`，并使用`user:pass`基本身份验证。在将指标发送到远程存储之前，会添加`instance="foobar"`和`job="vm"`标签给所有的指标：

```plain
/path/to/victoria-metrics \
  -pushmetrics.url=https://user:pass@maas.victoriametrics.com/api/v1/import/prometheus \
  -pushmetrics.extraLabel='instance="foobar"' \
  -pushmetrics.extraLabel='job="vm"'
```

### 参数调整？
+ 不需要调整 VictoriaMetrics - 它使用合理的默认启动参数，这些参数会自动根据可用的 CPU 和 RAM 资源进行调整。 
+ 操作系统不需要调优 - VictoriaMetrics已经针对默认的操作系统设置进行了优化。唯一的选项是增加操作系统中[打开文件数量的限制](https://medium.com/@muhammadtriwibowo/set-permanently-ulimit-n-open-files-in-ubuntu-4d61064429a)。这个建议不仅适用于 VictoriaMetrics，也适用于任何处理大量 HTTP 连接并将数据存储在磁盘上的服务。 
+ **VictoriaMetrics是一个写入密集型应用程序，其性能取决于磁盘性能**。因此，请注意其他可能[耗尽磁盘资源](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1521)的应用程序或实用工具（如[fstrim](http://manpages.ubuntu.com/manpages/bionic/man8/fstrim.8.html)）。 
+ 推荐使用`ext4`文件系统，并且[推荐在GCP上使用基于持久HDD硬盘作为持久存储](https://cloud.google.com/compute/docs/disks/#pdspecs)，因为它通过内部复制应对硬件故障影响，并且可以[动态调整大小](https://cloud.google.com/compute/docs/disks/add-persistent-disk#resize_pd)。如果您计划在`ext4`分区上存储超过`1TB`的数据或者计划将其扩展到超过`16TB`，则建议传递以下选项给`mkfs.ext4`：


```sh
mkfs.ext4 ... -O 64bit,huge_file,extent -T huge
```

## 数据运维 {#data-operation}
### 如何运用 snapshots {#snapshot}
VictoriaMetrics 可以为存储在`-storageDataPath`目录下的所有数据创建[即时快照](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#how-to-work-with-snapshots)。访问`http://:8428/snapshot/create`就可以创建即时快照。该接口将返回以下JSON响应：


```json
{"status":"ok","snapshot":"<snapshot-name>"}
```

快照是在`<-storageDataPath>/snapshots`目录下创建的，其中`<-storageDataPath>`是启动参数。可以随时使用[vmbackup]({{< relref "../components/vmbackup.md" >}})将快照归档到外部存储中用于备份。

- `http://<victoriametrics-addr>:8428/snapshot/list`接口包含了可用快照列表。
- `http://<victoriametrics-addr>:8428/snapshot/delete?snapshot=<snapshot-name>`则可删除`<snapshot-name>`快照.
- `http://<victoriametrics-addr>:8428/snapshot/delete_all`可删除所有快照。

从快照中恢复数据的步骤：

1. 使用命令`kill -INT`停掉 VictoriaMetrics。
2. 使用 [vmrestore]({{< relref "../components/vmrestore.md" >}}) 将快照内容恢复到`-storageDataPath`参数指定的目录。
3. 启动 VictoriaMetrics.

### 如何删除 Timeseries {#delete-timeseries}

发送请求到`http://:8428/api/v1/admin/tsdb/delete_series`，其中`<timeseries_selector_for_delete>`可以包含任何用于删除指标的时间序列选择器。该

删除接口不支持删除特定的时间范围，timeseries 只能完全删除。**已删除时间序列的存储空间不会立即释放**，它在后续的`part`合并过程中释放。

请注意，对于以前月份的数据可能永远不会进行后台合并，因此历史数据将无法释放存储空间。在这种情况下，[强制合并](#force-merge)可能有助于释放存储空间。

建议在实际删除指标之前使用调用`http://:8428/api/v1/series?match[]=<timeseries_selector_for_delete>`验证将要被删除的指标。默认情况下，此查询仅扫描过去5分钟内的系列，因此您可能需要调整开始和结束时间以获得匹配结果。

如果设置了`-deleteAuthKey`启动参数，则可以使用`authKey`保护`/api/v1/admin/tsdb/delete_series`接口，避免被误用。

Delete API 主要适用于以下情况：

一次性删除意外写入的无效（或不需要）时间序列。 由于`GDPR`而一次性删除用户数据。 以下情况不建议使用delete API，因为它会带来额外开销：

- 定期清理不需要的数据。只需防止将不需要的数据写入 VictoriaMetrics 即可。可以通过[Relabeling](#relabeling)来实现。 
- 通过删除不需要的时间序列来减少磁盘空间使用情况。这种方法无法达到预期效果，因为已删除的时间序列会一直占用磁盘空间直到下一次合并操作，而当删除过旧数据时可能因为`part`永远不会发生合并操作而得不到释放。强制合并可用于释放由旧数据占用的磁盘空间。请注意，VictoriaMetrics 不会从[倒排索引（也称为indexdb）]({{< relref "./dbengine.md#indexdb" >}})中删除已删除时间序列的条目。倒排索引每配置保留期清理一次。

最好使用`-retentionPeriod`启动参数以有效地修剪旧数据。

### 强制合并 {#force-merge}
VictoriaMetrics在[后台执行数据压缩](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)，以保持在接受新数据时的良好性能特征。这些压缩（合并）是独立地针对每个月份分区进行的。这意味着如果没有将新数据注入到这些分区中，则会停止对每个月份分区进行压缩。有时需要触发旧分区的压缩，例如为了释放被[删除Timeseries](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#ru-he-shan-chu-timeseries)占用的磁盘空间。在这种情况下，可以通过向`/internal/force_merge`发送请求来启动指定的每月分区上的强制合并操作?`partition_prefix=YYYY_MM`，其中`YYYY_MM`是每月分区名称。例如，`http://victoriametrics:8428/internal/force_merge?partition_prefix=2020_08`将会启动2020年8月份分区的强制合并操作。调用`/internal/force_merge`会立即返回，而相应的强制合并操作将继续在后台运行。 强制合并可能需要额外的CPU、磁盘IO和存储空间资源。在正常情况下不必运行强制合并操作，因为当有新数据注入时，VictoriaMetrics会自动在后台执行[最佳合并操作](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)。

### 补数据 {#backfilling}
VictoriaMetrics 通过[多种写入方法]({{< relref "../write/api.md" >}})将任意时间的历史数据补写到DB中。

建议在写入历史数据时，使用`-search.disableCache`启动参数禁用查询缓存，因为缓存假设数据都是实时写入的，历史数据是不变的。补写完成后再打开缓存，可以让`vmselect`缓存最新的历史数据块。

另一种解决方案是在补写完成后查询[/internal/resetRollupResultCache]({{< relref "../query/api.md#internalresetRollupResultCache" >}})接口，触发重置缓存。

### 数据更新

不支持

### 备份 {#backup}
VictoriaMetrics 支持使用 [vmbackup](https://docs.victoriametrics.com/vmbackup.html) and [vmrestore](https://docs.victoriametrics.com/vmrestore.html) 工具执行备份和恢复。

### 去重特性
VictoriaMetrics每个时间序列在每个`-dedup.minScrapeInterval`离散间隔内只保留一个具有最大时间戳的原始样本，如果`-dedup.minScrapeInterval`设置为正持续时间。例如，`-dedup.minScrapeInterval=60s`将在每个离散的60秒间隔内保留一个具有最大时间戳的原始样本。这与[Prometheus中的过期规则](https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness)相一致。

如果给定的`-dedup.minScrapeInterval`离散间隔上有多个具有相同时间戳的原始样本，则保留值最大的样本。

请注意，要进行去重操作，原始样本的标签必须完全相同。例如，这就是为什么[vmagents HA](https://docs.victoriametrics.com/vmagent.html#high-availability)对需要配置完全相同。

如果启用了降采样功能，则`-dedup.minScrapeInterval=D`等效于`-downsampling.period=0s:D`。因此可以同时使用去重和[降采样](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#downsampling)而不会出现问题。

建议将`-dedup.minScrapeInterval`的推荐值设置为 Prometheus 配置文件中`scrape_interval`的值。建议所有抓取目标都使用统一的抓取间隔，请参阅详细信息[文章](https://www.robustperception.io/keep-it-simple-scrape_interval-id)。

通过去重操作可以减少磁盘空间占用量，特别是当多个配置完全相同的 vmagent 或 Prometheus 实例以 HA 对形式写入数据到同一个 VictoriaMetrics 实例时更加有效。这些 vmagent 或 Prometheus 实例必须在其配置文件中具有相同的`external_labels`部分，以便将数据写入同一个时间序列。另请参阅[如何设置多个 vmagent 实例来抓取相同目标](https://docs.victoriametrics.com/vmagent.html#scraping-big-number-of-targets)。

建议为每个不同的 vmagent HA 对实例传递不同的`-promscrape.cluster.name `值，这样去重操作就会一致地保留一个 vmagent 实例的样本，并从其他`vmagent`实例中删除重复样本。请参阅[详细文档](https://docs.victoriametrics.com/vmagent.html#high-availability)了解更多信息。

### 多租户 {#tenant}

单机版的 VictoriaMetrics 不支持多租户。请使用[集群版本]({{< relref "./cluster.md#tenant" >}})。

### 多副本 {#replication}

单机版的 VictoriaMetrics 不支持应用级别的复制。请使用集群版本代替。详细信息请参阅[这些文档]({{< relref "./cluster.md#replication" >}})。 

存储级别的复制可以考虑使用云存储存储，如[Google Cloud磁盘](https://cloud.google.com/compute/docs/disks#pdspecs)。 

还可以查看[高可用性文档](#high-availability)和[备份文档](#backup)。

### 扩展性和集群版本

尽管单机版的 VictoriaMetrics 无法扩展到多个节点，但它在资源使用方面进行了优化，包括存储大小/带宽/IOPS、RAM和CPU。这意味着一个单机版的 VictoriaMetrics 可以在垂直方向上扩展，并替代其他解决方案（如Thanos、Uber M3、InfluxDB或TimescaleDB）的等规模集群。请参阅垂直扩展的[基准测试结果](https://medium.com/@valyala/measuring-vertical-scalability-for-time-series-databases-in-google-cloud-92550d78d8ae)。

**首先尝试使用单机版的 VictoriaMetrics，如果您仍然需要针对大型 Prometheus 部署进行横向扩展的长期远程存储，则可以切换到[集群版本]({{< relref "./cluster.md" >}})。**

### Relabeling {#relabeling}
VictoriaMetrics 支持对所有接收到的指标进行与 Prometheus 兼容的重新标注处理，只需使用`-relabelConfig`启动参数指定一个包含`relabel_config`条目列表的文件即可。`-relabelConfig`也可以指向http或https URL。例如，`-relabelConfig=https://config-server/relabel_config.yml`。 

以下文档可能对理解重新标注处理有所帮助：

+ [Cookbook for common relabeling tasks](https://docs.victoriametrics.com/relabeling.html).
+ [Relabeling tips and tricks](https://valyala.medium.com/how-to-use-relabeling-in-prometheus-and-victoriametrics-8b90fc22c4b2).

`-relabelConfig`文件中可以包含特殊的占位符，形式为`%{ENV_VAR}`，它们将被相应的环境变量值替换。

`-relabelConfig`文件示例内容：

```yaml
# Add {cluster="dev"} label.
- target_label: cluster
  replacement: dev

# Drop the metric (or scrape target) with `{__meta_kubernetes_pod_container_init="true"}`label.
- action: drop
  source_labels: [__meta_kubernetes_pod_container_init]
  regex: true
```

VictoriaMetrics 扩展了重新标注功能，例如 Graphite 风格的再标注。有关更多详细信息，请参阅[这些文档]({{< relref "../components/vmagent.md#relabeling" >}})。

可以在`http://victoriametrics:8428/metric-relabel-debug`页面或我们的[在线工具](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/#/relabeling)上调试 Relabel。有关更多详细信息，请参阅[这些文档]({{< relref "../components/vmagent.md#relabel-debug" >}})。


## 高级特性

### 清除 Cache {#cache-removal}
VictoriaMetrics 使用各种内部缓存。这些缓存在组件被优雅关闭时（例如通过发送`SIGINT`信号停止VictoriaMetrics）存储到`<-storageDataPath>/cache`目录中。下次启动VictoriaMetrics时会读取这些缓存。

如果需要在下次启动时删除此类缓存。可以通过以下方式完成：

+ 在 VictoriaMetrics 停止后手动删除`<-storageDataPath>/cache`目录。
+ 在重新启动 VictoriaMetrics 之前将`reset_cache_on_startup`文件放置在`<-storageDataPath>/cache`目录中。 在这种情况下，VictoriaMetrics 将自动在下次启动时删除所有缓存。有关详细信息，请参阅此[issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1447)。

### Rollup 结果缓存 {#rollup cache}

VictoriaMetrics 默认缓存查询响应数据。这可以提供在`time`,`start`和`end`时间参数不断递增的场景下对`/api/v1/query`和`/api/v1/query_range`的重复查询性能。（比如，一个 Grafana 页面定时刷新，就是反复发送重复请求，其中只有`time`,`start`和`start`参数随着时间变化而更新）

如果有历史数据补写到 DB 中，该缓存机制就会导致 VictoriaMetrics 返回不正确的结果。详情请参见[这些文档](#backfilling)。

可以通过启动参数`-search.disableCache`禁用 VictoriaMetrics 的全局 rollup 缓存，也可以在请求`/api/v1/query`和`/api/v1/query_range`接口时带上`nocache=1`查询参数来禁用该缓存。。

### Cache 调整

VictoriaMetrics 使用各种内存缓存来提升数据写入和查询性能。每种类型的缓存都在`/metrics`下暴露如下指标：

+ `vm_cache_size_bytes`- 实际的 cache 大小
+ `vm_cache_size_max_bytes`- cache 最大限制 limit
+ `vm_cache_requests_total`- cache 的请求数
+ `vm_cache_misses_total`- cache miss 的数量
+ `vm_cache_entries`- cache 中的实体数

单机版和集群版的 Grafana 仪表板都包含了缓存部分，其中将缓存指标的可视化。面板显示了每种类型缓存的当前内存使用情况，以及缓存命中率。如果命中率接近100%，则表示缓存效率已经非常高，不需要进行任何调整。在故障排除部分的面板"`Cache usage %`"显示了按类型使用的缓存大小与允许大小之间的百分比。如果百分比低于100%，则无需进一步调整。

请注意，默认缓存大小已根据最实际的场景和运行环境进行了精心调整。只有在您理解其影响并且`vmstorage`具有足够空闲内存来容纳新的缓存大小时才需要更改默认启动。

要覆盖默认值，请参阅带有`-storage.cacheSize`前缀的启动参数。可以在[此处](#flags)查看所有启动参数的完整描述。


### 基数限制 {#cardinality}

默认情况下，VictoriaMetrics 不限制存储的时间序列数量。可以通过设置以下启动参数来强制执行限制：

+ `-storage.maxHourlySeries`- 限制了在最后一个小时内可以添加的时间序列数量。对于限制[活动时间序列]({{< relref "../faq.md#what-is-an-active-time-series" >}})的数量非常有用。
+ `-storage.maxDailySeries`- 限制了最后一天可以添加的时间序列数量。对于限制每日[替换率]({{< relref "../faq.md#what-is-high-churn-rate" >}})非常有用。

可以同时设置这两个限制。如果达到任何一个限制，那么新时间序列的输入样本将被丢弃。被丢弃的系列样本会以`WARN`级别记录在日志中。

超出限制的情况可以通过以下指标进行监控：

+ `vm_hourly_series_limit_rows_dropped_total`- 由于超过每小时限制的唯一时间序列数量，被丢弃指标数量。
+ `vm_hourly_series_limit_max_series`- 小时级限制，通过`-storage.maxHourlySeries`启动参数设置的值。

`vm_hourly_series_limit_current_series`- 过去一小时内 timeseries 的数量。当过去一小时内 timeseries 的数量超过`-storage.maxHourlySeries`的`90%`时，以下查询可能会有用于告警：

```plain
vm_hourly_series_limit_current_series / vm_hourly_series_limit_max_series > 0.9
```

+ `vm_daily_series_limit_rows_dropped_total`- 由于超过每日唯一时间序列数量限制，被丢弃指标数量。
+ `vm_daily_series_limit_max_series`- 天级别 timeseries 限制，通过`-storage.maxDailySeries`启动参数设置的值。

`vm_daily_series_limit_current_series`- 在过去的一天中，timeseries 数量。当 timeseires 在过去的一天内超过`-storage.maxDailySeries`的`90%`时，以下查询可能会有用于告警：

```plain
vm_daily_series_limit_current_series / vm_daily_series_limit_max_series > 0.9
```

这些限制是近似值，大约有`1%`的误差；为了降低限制逻辑的资源消耗，内部用布隆过滤器实现，因此有点误差。

更多进阶内容参见 [vmagent 的基数限制]({{< relref "../components/vmagent.md#cardinality-limiter" >}})

### 查询追踪 {#trace}

VictoriaMetrics支持查询追踪，可用于确定查询处理过程中的瓶颈。这类似于 Postgresql 的`EXPLAIN ANALYZE`。

可以通过传递`trace=1`查询参数来启用特定查询的查询追踪。在这种情况下，VictoriaMetrics将 查询跟踪放入输出JSON的trace字段中。

例如，以下命令：

```sh
curl http://localhost:8428/api/v1/query_range -d 'query=2*rand()' -d 'start=-1h' -d 'step=1m' -d 'trace=1' | jq '.trace'
```

会返回下面的 trace 信息:


```json
{
  "duration_msec": 0.099,
  "message": "/api/v1/query_range: start=1654034340000, end=1654037880000, step=60000, query=\"2*rand()\": series=1",
  "children": [
    {
      "duration_msec": 0.034,
      "message": "eval: query=2 * rand(), timeRange=[1654034340000..1654037880000], step=60000, mayCache=true: series=1, points=60, pointsPerSeries=60",
      "children": [
        {
          "duration_msec": 0.032,
          "message": "binary op \"*\": series=1",
          "children": [
            {
              "duration_msec": 0.009,
              "message": "eval: query=2, timeRange=[1654034340000..1654037880000], step=60000, mayCache=true: series=1, points=60, pointsPerSeries=60"
            },
            {
              "duration_msec": 0.017,
              "message": "eval: query=rand(), timeRange=[1654034340000..1654037880000], step=60000, mayCache=true: series=1, points=60, pointsPerSeries=60",
              "children": [
                {
                  "duration_msec": 0.015,
                  "message": "transform rand(): series=1"
                }
              ]
            }
          ]
        }
      ]
    },
    {
      "duration_msec": 0.004,
      "message": "sort series by metric name and labels"
    },
    {
      "duration_msec": 0.044,
      "message": "generate /api/v1/query_range response for series=1, points=60"
    }
  ]
}
```

所有跟踪中的持续时间和时间戳都以毫秒为单位。

查询跟踪默认是开启的。可以通过在 VictoriaMetrics 上传递`-denyQueryTracing`启动参数来关闭。

[VMUI]({{< relref "../components/vmui.md" >}}) 提供了一个 UI 界面:

+ 对于 query 追踪 - 只需要选中`Trace query`复选框，然后重新跑一下查询语句就可以得到执行 Trace。
+ 对于探索自定义追踪 - 进入`Trace analyzer`页面，然后上传或粘贴 trace 的 JSON 数据信息。

### 安全 {#security}
一般安全建议：

+ 所有的 VictoriaMetrics 组件必须在受保护的私有网络中运行，不能直接从不可信任的网络（如互联网）访问。例外情况是[vmauth](https://docs.victoriametrics.com/vmauth.html)和[vmgateway](https://docs.victoriametrics.com/vmgateway.html)。
+ 来自不可信任网络到达 VictoriaMetrics 组件的所有请求都必须通过认证代理（例如 vmauth 或 vmgateway）进行。代理必须设置适当的身份验证和授权。
+ 在配置位于 VictoriaMetric s组件前面的认证代理时，最好使用允许 API 接口列表，并禁止对其他接口进行访问。

VictoriaMetrics 提供了下面这些安全相关的启动参数：

+ `-tls`, `-tlsCertFile`and `-tlsKeyFile`用来开启 HTTPS.
+ `-httpAuth.username`and `-httpAuth.password`使用 [HTTP Basic Authentication](https://en.wikipedia.org/wiki/Basic_access_authentication) 来保护所有的 HTTP 接口。
+ `-deleteAuthKey`用来保护`/api/v1/admin/tsdb/delete_series`接口。参见 [how to delete time series](https://docs.victoriametrics.com/#how-to-delete-time-series).
+ `-snapshotAuthKey`用来保护`/snapshot*`一系列接口。参见 [how to work with snapshots](https://docs.victoriametrics.com/#how-to-work-with-snapshots).
+ `-forceMergeAuthKey`用来保护`/internal/force_merge`接口。参见 [force merge docs](https://docs.victoriametrics.com/#forced-merge).
+ `-search.resetCacheAuthKey`用来保护`/internal/resetRollupResultCache`接口。 更多详情参见 [backfilling](#backfilling)。
+ `-configAuthKey`用来保护`/config`接口，因为它可能包含一些敏感的信息，比如密码。
+ `-flagsAuthKey`用来保护`/flags`接口。
+ `-pprofAuthKey`用来保护`/debug/pprof/*`接口，这是用来做性能分析的 [profiling](https://docs.victoriametrics.com/#profiling)。
+ `-denyQueryTracing`用来禁用 [query tracing](https://docs.victoriametrics.com/#query-tracing).

明确设置用于使用 Graphite 和 OpenTSDB 格式进行数据写入的TCP和UDP端口的内部接口。例如，将`-graphiteListenAddr=:2003`替换为`-graphiteListenAddr=<internal_iface_ip>:2003`。这样可以防止来自不受信任的网络接口的意外请求。

参见 [集群版安全建议]({{< relref "./cluster.md#security" >}}) 以及 [网站的常规安全策略](https://victoriametrics.com/security/).


## 建议总结
+ 建议使用默认启动参数，不要自己去设置它。
+ 建议在故障排除过程中检查日志，因为它们可能包含有用的信息。
+ 建议至少保留`50%`的CPU、磁盘IO和RAM资源作为备用，这样 VictoriaMetric s就可以处理突发流量是不出现性能问题。
+ VictoriaMetrics 需要空闲磁盘空间将数据文件合并成更大的文件。当没有足够的剩余空间时，它可能会变慢。因此，请确保`-storageDataPath`目录至少有`20%`的可用空间。剩余可用空间量可以通过`vm_free_disk_space_bytes`指标进行监控。存储在磁盘上的数据总大小可以通过`vm_data_size_bytes`指标之和进行监控。还可以查看`vm_merge_need_free_disk_space`指标，如果由于缺乏免费磁盘空间而无法启动后台合并，则其值将设置为大于`0`.该值显示每月分区数，在拥有更多免费磁盘空间时将启动后台合并。
+ VictoriaMetrics 会将传入数据缓冲到内存中，并在几秒钟后将其刷新到持久存储中。这可能会导致以下“问题”：
    - 数据写入后要等几秒数据才能进行查询。可以通过请求`/internal/force_flush`http 接口将内存缓冲区刷新到可搜索部分。此接口主要用于测试和调试目的。
    - 在非正常关闭（即OOM、`kill -9`或硬件故障）时，最后几秒钟写入的数据可能会丢失。`-inmemoryDataFlushInterval`启动参数允许控制将内存中的数据刷新到持久存储的频率。
+ 如果 VictoriaMetrics 工作缓慢，并且每秒写入`100K`个数据点占用超过一个CPU核心，则很可能是当前RAM量对于太多[活动时间序列]({{< relref "../faq.md#what-is-active-timeseries" >}})来说不足够了。VictoriaMetrics 开放了`vm_slow_*`指标，例如`vm_slow_row_inserts_total`和`vm_slow_metric_name_loads_total`，它们可以用作RAM数量不足的指示器。建议增加节点上 VictoriaMetrics 所使用的RAM量以改善摄取和查询性能。
+ 如果同一 Metric 的 Label 顺序如果随时间有变化（例如`metric{k1="v1",k2="v2"}`可能变为`metric{k2="v2",k1="v1"}`），则建议使用`-sortLabels`启动参数运行 VictoriaMetrics，以减少内存使用和CPU使用率。
+ VictoriaMetrics 优先考虑数据写入而不是数据查询。因此，如果没有足够的资源进行数据写入，则数据查询可能会显著减慢。
+ 如果 VictoriaMetrics 由于磁盘错误导致某些部分损坏而无法工作，则只需删除带有损坏部分的目录即可。在 VictoriaMetrics 未运行时，安全地删除`<-storageDataPath>/data/{big,small}/YYYY_MM`目录下的子目录可以恢复VictoriaMetrics，但会丢失已存储在被删除损坏部分中的数据。将来将创建vmrecover工具以自动从此类错误中恢复。
+ 如果您在图表上看到断点，请尝试通过向`/internal/resetRollupResultCache`发送请求来重置缓存。如果这样可以消除图表上的空白断点间隙，则很可能是将早于`-search.cacheTimestampOffset`时间戳的数据更新了。
+ 如果您从 InfluxDB 或 TimescaleDB 切换过来，可能需要设置`-search.setLookbackToStep`启动参数。这将抑制 VictoriaMetrics 使用的默认间隙填充算法-默认情况下，它假设每个时间序列是连续的而不是离散的，因此会用固定间隔填补真实样本之间的空白。
+ 通过[/api/v1/status/tsdb]({{< relref "../query/api.md#apiv1statustsdb-tsdb-stats" >}})接口可以确定导致高基数或高替换率的指标和标签。
+ 如果要在 VictoriaMetrics 中记录新时间序列，请传递`-logNewSeries`启动参数。
+ VictoriaMetrics 通过`-maxLabelsPerTimeseries`启动参数限制每个度量指标的标签数量。这可以防止写入具有太多标签的指标。建议监视`vm_metrics_with_dropped_labels_total`指标以确定是否需要根据线上情况调整`-maxLabelsPerTimeseries`。
+ 如果您在 VictoriaMetrics 中存储 Graphite 指标（如`foo.bar.baz`），则可以使用`{__graphite__="foo.*.baz"}`过滤器选择此类指标。详细信息请参阅[相关文档]({{< relref "../query/metricsql/_index.md#graphite-filter" >}})。
+ 在数据摄取期间，VictoriaMetrics会忽略`NaN`值。

更多参见[故障排查文档]({{< relref "./deploy.md#troubleshooting" >}})。

## 运行参数 {#flags}
使用`-help`参数来查看支持的所有运行参数列表和参数功能描述。

```bash
-bigMergeConcurrency int
   Deprecated: this flag does nothing
-blockcache.missesBeforeCaching int
   The number of cache misses before putting the block into cache. Higher values may reduce indexdb/dataBlocks cache size at the cost of higher CPU and disk read usage (default 2)
-cacheExpireDuration duration
   Items are removed from in-memory caches after they aren't accessed for this duration. Lower values may reduce memory usage at the cost of higher CPU usage. See also -prevCacheRemovalPercent (default 30m0s)
-configAuthKey value
   Authorization key for accessing /config page. It must be passed via authKey query arg. It overrides -httpAuth.*
   Flag value can be read from the given file when using -configAuthKey=file:///abs/path/to/file or -configAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -configAuthKey=http://host/path or -configAuthKey=https://host/path
-csvTrimTimestamp duration
   Trim timestamps when importing csv data to this duration. Minimum practical duration is 1ms. Higher duration (i.e. 1s) may be used for reducing disk space usage for timestamp data (default 1ms)
-datadog.maxInsertRequestSize size
   The maximum size in bytes of a single DataDog POST request to /datadog/api/v2/series
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 67108864)
-datadog.sanitizeMetricName
   Sanitize metric names for the ingested DataDog data to comply with DataDog behaviour described at https://docs.datadoghq.com/metrics/custom_metrics/#naming-custom-metrics (default true)
-dedup.minScrapeInterval duration
   Leave only the last sample in every time series per each discrete interval equal to -dedup.minScrapeInterval > 0. See also -streamAggr.dedupInterval and https://docs.victoriametrics.com/#deduplication
-deleteAuthKey value
   authKey for metrics' deletion via /api/v1/admin/tsdb/delete_series and /tags/delSeries
   Flag value can be read from the given file when using -deleteAuthKey=file:///abs/path/to/file or -deleteAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -deleteAuthKey=http://host/path or -deleteAuthKey=https://host/path
-denyQueriesOutsideRetention
   Whether to deny queries outside the configured -retentionPeriod. When set, then /api/v1/query_range would return '503 Service Unavailable' error for queries with 'from' value outside -retentionPeriod. This may be useful when multiple data sources with distinct retentions are hidden behind query-tee
-denyQueryTracing
   Whether to disable the ability to trace queries. See https://docs.victoriametrics.com/#query-tracing
-downsampling.period array
   Comma-separated downsampling periods in the format 'offset:period'. For example, '30d:10m' instructs to leave a single sample per 10 minutes for samples older than 30 days. When setting multiple downsampling periods, it is necessary for the periods to be multiples of each other. See https://docs.victoriametrics.com/#downsampling for details. This flag is available only in VictoriaMetrics enterprise. See https://docs.victoriametrics.com/enterprise/
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-dryRun
   Whether to check config files without running VictoriaMetrics. The following config files are checked: -promscrape.config, -relabelConfig and -streamAggr.config. Unknown config entries aren't allowed in -promscrape.config by default. This can be changed with -promscrape.config.strictParse=false command-line flag
-enableTCP6
   Whether to enable IPv6 for listening and dialing. By default, only IPv4 TCP and UDP are used
-envflag.enable
   Whether to enable reading flags from environment variables in addition to the command line. Command line flag values have priority over values from environment vars. Flags are read only from the command line if this flag isn't set. See https://docs.victoriametrics.com/#environment-variables for more details
-envflag.prefix string
   Prefix for environment variables if -envflag.enable is set
-eula
   Deprecated, please use -license or -licenseFile flags instead. By specifying this flag, you confirm that you have an enterprise license and accept the ESA https://victoriametrics.com/legal/esa/ . This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
-filestream.disableFadvise
   Whether to disable fadvise() syscall when reading large data files. The fadvise() syscall prevents from eviction of recently accessed data from OS page cache during background merges and backups. In some rare cases it is better to disable the syscall if it uses too much CPU
-finalMergeDelay duration
   Deprecated: this flag does nothing
-flagsAuthKey value
   Auth key for /flags endpoint. It must be passed via authKey query arg. It overrides -httpAuth.*
   Flag value can be read from the given file when using -flagsAuthKey=file:///abs/path/to/file or -flagsAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -flagsAuthKey=http://host/path or -flagsAuthKey=https://host/path
-forceFlushAuthKey value
   authKey, which must be passed in query string to /internal/force_flush pages
   Flag value can be read from the given file when using -forceFlushAuthKey=file:///abs/path/to/file or -forceFlushAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -forceFlushAuthKey=http://host/path or -forceFlushAuthKey=https://host/path
-forceMergeAuthKey value
   authKey, which must be passed in query string to /internal/force_merge pages
   Flag value can be read from the given file when using -forceMergeAuthKey=file:///abs/path/to/file or -forceMergeAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -forceMergeAuthKey=http://host/path or -forceMergeAuthKey=https://host/path
-fs.disableMmap
   Whether to use pread() instead of mmap() for reading data files. By default, mmap() is used for 64-bit arches and pread() is used for 32-bit arches, since they cannot read data files bigger than 2^32 bytes in memory. mmap() is usually faster for reading small data chunks than pread()
-graphite.sanitizeMetricName
   Sanitize metric names for the ingested Graphite data. See https://docs.victoriametrics.com/#how-to-send-data-from-graphite-compatible-agents-such-as-statsd
-graphiteListenAddr string
   TCP and UDP address to listen for Graphite plaintext data. Usually :2003 must be set. Doesn't work if empty. See also -graphiteListenAddr.useProxyProtocol
-graphiteListenAddr.useProxyProtocol
   Whether to use proxy protocol for connections accepted at -graphiteListenAddr . See https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
-graphiteTrimTimestamp duration
   Trim timestamps for Graphite data to this duration. Minimum practical duration is 1s. Higher duration (i.e. 1m) may be used for reducing disk space usage for timestamp data (default 1s)
-http.connTimeout duration
   Incoming connections to -httpListenAddr are closed after the configured timeout. This may help evenly spreading load among a cluster of services behind TCP-level load balancer. Zero value disables closing of incoming connections (default 2m0s)
-http.disableResponseCompression
   Disable compression of HTTP responses to save CPU resources. By default, compression is enabled to save network bandwidth
-http.header.csp string
   Value for 'Content-Security-Policy' header, recommended: "default-src 'self'"
-http.header.frameOptions string
   Value for 'X-Frame-Options' header
-http.header.hsts string
   Value for 'Strict-Transport-Security' header, recommended: 'max-age=31536000; includeSubDomains'
-http.idleConnTimeout duration
   Timeout for incoming idle http connections (default 1m0s)
-http.maxGracefulShutdownDuration duration
   The maximum duration for a graceful shutdown of the HTTP server. A highly loaded server may require increased value for a graceful shutdown (default 7s)
-http.pathPrefix string
   An optional prefix to add to all the paths handled by http server. For example, if '-http.pathPrefix=/foo/bar' is set, then all the http requests will be handled on '/foo/bar/*' paths. This may be useful for proxied requests. See https://www.robustperception.io/using-external-urls-and-proxies-with-prometheus
-http.shutdownDelay duration
   Optional delay before http server shutdown. During this delay, the server returns non-OK responses from /health page, so load balancers can route new requests to other servers
-httpAuth.password value
   Password for HTTP server's Basic Auth. The authentication is disabled if -httpAuth.username is empty
   Flag value can be read from the given file when using -httpAuth.password=file:///abs/path/to/file or -httpAuth.password=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -httpAuth.password=http://host/path or -httpAuth.password=https://host/path
-httpAuth.username string
   Username for HTTP server's Basic Auth. The authentication is disabled if empty. See also -httpAuth.password
-httpListenAddr array
   TCP addresses to listen for incoming http requests. See also -tls and -httpListenAddr.useProxyProtocol
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-httpListenAddr.useProxyProtocol array
   Whether to use proxy protocol for connections accepted at the corresponding -httpListenAddr . See https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt . With enabled proxy protocol http server cannot serve regular /metrics endpoint. Use -pushmetrics.url for metrics pushing
   Supports array of values separated by comma or specified via multiple flags.
   Empty values are set to false.
-import.maxLineLen size
   The maximum length in bytes of a single line accepted by /api/v1/import; the line length can be limited with 'max_rows_per_line' query arg passed to /api/v1/export
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 10485760)
-influx.databaseNames array
   Comma-separated list of database names to return from /query and /influx/query API. This can be needed for accepting data from Telegraf plugins such as https://github.com/fangli/fluent-plugin-influxdb
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-influx.maxLineSize size
   The maximum size in bytes for a single InfluxDB line during parsing
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 262144)
-influxDBLabel string
   Default label for the DB name sent over '?db={db_name}' query parameter (default "db")
-influxListenAddr string
   TCP and UDP address to listen for InfluxDB line protocol data. Usually :8089 must be set. Doesn't work if empty. This flag isn't needed when ingesting data over HTTP - just send it to http://<victoriametrics>:8428/write . See also -influxListenAddr.useProxyProtocol
-influxListenAddr.useProxyProtocol
   Whether to use proxy protocol for connections accepted at -influxListenAddr . See https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
-influxMeasurementFieldSeparator string
   Separator for '{measurement}{separator}{field_name}' metric name when inserted via InfluxDB line protocol (default "_")
-influxSkipMeasurement
   Uses '{field_name}' as a metric name while ignoring '{measurement}' and '-influxMeasurementFieldSeparator'
-influxSkipSingleField
   Uses '{measurement}' instead of '{measurement}{separator}{field_name}' for metric name if InfluxDB line contains only a single field
-influxTrimTimestamp duration
   Trim timestamps for InfluxDB line protocol data to this duration. Minimum practical duration is 1ms. Higher duration (i.e. 1s) may be used for reducing disk space usage for timestamp data (default 1ms)
-inmemoryDataFlushInterval duration
   The interval for guaranteed saving of in-memory data to disk. The saved data survives unclean shutdowns such as OOM crash, hardware reset, SIGKILL, etc. Bigger intervals may help increase the lifetime of flash storage with limited write cycles (e.g. Raspberry PI). Smaller intervals increase disk IO load. Minimum supported value is 1s (default 5s)
-insert.maxQueueDuration duration
   The maximum duration to wait in the queue when -maxConcurrentInserts concurrent insert requests are executed (default 1m0s)
-internStringCacheExpireDuration duration
   The expiry duration for caches for interned strings. See https://en.wikipedia.org/wiki/String_interning . See also -internStringMaxLen and -internStringDisableCache (default 6m0s)
-internStringDisableCache
   Whether to disable caches for interned strings. This may reduce memory usage at the cost of higher CPU usage. See https://en.wikipedia.org/wiki/String_interning . See also -internStringCacheExpireDuration and -internStringMaxLen
-internStringMaxLen int
   The maximum length for strings to intern. A lower limit may save memory at the cost of higher CPU usage. See https://en.wikipedia.org/wiki/String_interning . See also -internStringDisableCache and -internStringCacheExpireDuration (default 500)
-license string
   License key for VictoriaMetrics Enterprise. See https://victoriametrics.com/products/enterprise/ . Trial Enterprise license can be obtained from https://victoriametrics.com/products/enterprise/trial/ . This flag is available only in Enterprise binaries. The license key can be also passed via file specified by -licenseFile command-line flag
-license.forceOffline
   Whether to enable offline verification for VictoriaMetrics Enterprise license key, which has been passed either via -license or via -licenseFile command-line flag. The issued license key must support offline verification feature. Contact info@victoriametrics.com if you need offline license verification. This flag is available only in Enterprise binaries
-licenseFile string
   Path to file with license key for VictoriaMetrics Enterprise. See https://victoriametrics.com/products/enterprise/ . Trial Enterprise license can be obtained from https://victoriametrics.com/products/enterprise/trial/ . This flag is available only in Enterprise binaries. The license key can be also passed inline via -license command-line flag
-logNewSeries
   Whether to log new series. This option is for debug purposes only. It can lead to performance issues when big number of new series are ingested into VictoriaMetrics
-loggerDisableTimestamps
   Whether to disable writing timestamps in logs
-loggerErrorsPerSecondLimit int
   Per-second limit on the number of ERROR messages. If more than the given number of errors are emitted per second, the remaining errors are suppressed. Zero values disable the rate limit
-loggerFormat string
   Format for logs. Possible values: default, json (default "default")
-loggerJSONFields string
   Allows renaming fields in JSON formatted logs. Example: "ts:timestamp,msg:message" renames "ts" to "timestamp" and "msg" to "message". Supported fields: ts, level, caller, msg
-loggerLevel string
   Minimum level of errors to log. Possible values: INFO, WARN, ERROR, FATAL, PANIC (default "INFO")
-loggerMaxArgLen int
   The maximum length of a single logged argument. Longer arguments are replaced with 'arg_start..arg_end', where 'arg_start' and 'arg_end' is prefix and suffix of the arg with the length not exceeding -loggerMaxArgLen / 2 (default 1000)
-loggerOutput string
   Output for the logs. Supported values: stderr, stdout (default "stderr")
-loggerTimezone string
   Timezone to use for timestamps in logs. Timezone must be a valid IANA Time Zone. For example: America/New_York, Europe/Berlin, Etc/GMT+3 or Local (default "UTC")
-loggerWarnsPerSecondLimit int
   Per-second limit on the number of WARN messages. If more than the given number of warns are emitted per second, then the remaining warns are suppressed. Zero values disable the rate limit
-maxConcurrentInserts int
   The maximum number of concurrent insert requests. Set higher value when clients send data over slow networks. Default value depends on the number of available CPU cores. It should work fine in most cases since it minimizes resource usage. See also -insert.maxQueueDuration (default 32)
-maxInsertRequestSize size
   The maximum size in bytes of a single Prometheus remote_write API request
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 33554432)
-maxLabelValueLen int
   The maximum length of label values in the accepted time series. Longer label values are truncated. In this case the vm_too_long_label_values_total metric at /metrics page is incremented (default 4096)
-maxLabelsPerTimeseries int
   The maximum number of labels accepted per time series. Superfluous labels are dropped. In this case the vm_metrics_with_dropped_labels_total metric at /metrics page is incremented (default 30)
-memory.allowedBytes size
   Allowed size of system memory VictoriaMetrics caches may occupy. This option overrides -memory.allowedPercent if set to a non-zero value. Too low a value may increase the cache miss rate usually resulting in higher CPU and disk IO usage. Too high a value may evict too much data from the OS page cache resulting in higher disk IO usage
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-memory.allowedPercent float
   Allowed percent of system memory VictoriaMetrics caches may occupy. See also -memory.allowedBytes. Too low a value may increase cache miss rate usually resulting in higher CPU and disk IO usage. Too high a value may evict too much data from the OS page cache which will result in higher disk IO usage (default 60)
-metrics.exposeMetadata
   Whether to expose TYPE and HELP metadata at the /metrics page, which is exposed at -httpListenAddr . The metadata may be needed when the /metrics page is consumed by systems, which require this information. For example, Managed Prometheus in Google Cloud - https://cloud.google.com/stackdriver/docs/managed-prometheus/troubleshooting#missing-metric-type
-metricsAuthKey value
   Auth key for /metrics endpoint. It must be passed via authKey query arg. It overrides -httpAuth.*
   Flag value can be read from the given file when using -metricsAuthKey=file:///abs/path/to/file or -metricsAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -metricsAuthKey=http://host/path or -metricsAuthKey=https://host/path
-mtls array
   Whether to require valid client certificate for https requests to the corresponding -httpListenAddr . This flag works only if -tls flag is set. See also -mtlsCAFile . This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
   Supports array of values separated by comma or specified via multiple flags.
   Empty values are set to false.
-mtlsCAFile array
   Optional path to TLS Root CA for verifying client certificates at the corresponding -httpListenAddr when -mtls is enabled. By default the host system TLS Root CA is used for client certificate verification. This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-newrelic.maxInsertRequestSize size
   The maximum size in bytes of a single NewRelic request to /newrelic/infra/v2/metrics/events/bulk
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 67108864)
-opentelemetry.usePrometheusNaming
   Whether to convert metric names and labels into Prometheus-compatible format for the metrics ingested via OpenTelemetry protocol; see https://docs.victoriametrics.com/#sending-data-via-opentelemetry
-opentsdbHTTPListenAddr string
   TCP address to listen for OpenTSDB HTTP put requests. Usually :4242 must be set. Doesn't work if empty. See also -opentsdbHTTPListenAddr.useProxyProtocol
-opentsdbHTTPListenAddr.useProxyProtocol
   Whether to use proxy protocol for connections accepted at -opentsdbHTTPListenAddr . See https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
-opentsdbListenAddr string
   TCP and UDP address to listen for OpenTSDB metrics. Telnet put messages and HTTP /api/put messages are simultaneously served on TCP port. Usually :4242 must be set. Doesn't work if empty. See also -opentsdbListenAddr.useProxyProtocol
-opentsdbListenAddr.useProxyProtocol
   Whether to use proxy protocol for connections accepted at -opentsdbListenAddr . See https://www.haproxy.org/download/1.8/doc/proxy-protocol.txt
-opentsdbTrimTimestamp duration
   Trim timestamps for OpenTSDB 'telnet put' data to this duration. Minimum practical duration is 1s. Higher duration (i.e. 1m) may be used for reducing disk space usage for timestamp data (default 1s)
-opentsdbhttp.maxInsertRequestSize size
   The maximum size of OpenTSDB HTTP put request
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 33554432)
-opentsdbhttpTrimTimestamp duration
   Trim timestamps for OpenTSDB HTTP data to this duration. Minimum practical duration is 1ms. Higher duration (i.e. 1s) may be used for reducing disk space usage for timestamp data (default 1ms)
-pprofAuthKey value
   Auth key for /debug/pprof/* endpoints. It must be passed via authKey query arg. It overrides -httpAuth.*
   Flag value can be read from the given file when using -pprofAuthKey=file:///abs/path/to/file or -pprofAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -pprofAuthKey=http://host/path or -pprofAuthKey=https://host/path
-precisionBits int
   The number of precision bits to store per each value. Lower precision bits improves data compression at the cost of precision loss (default 64)
-prevCacheRemovalPercent float
   Items in the previous caches are removed when the percent of requests it serves becomes lower than this value. Higher values reduce memory usage at the cost of higher CPU usage. See also -cacheExpireDuration (default 0.1)
-promscrape.azureSDCheckInterval duration
   Interval for checking for changes in Azure. This works only if azure_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#azure_sd_configs for details (default 1m0s)
-promscrape.cluster.memberLabel string
   If non-empty, then the label with this name and the -promscrape.cluster.memberNum value is added to all the scraped metrics. See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more info
-promscrape.cluster.memberNum string
   The number of vmagent instance in the cluster of scrapers. It must be a unique value in the range 0 ... promscrape.cluster.membersCount-1 across scrapers in the cluster. Can be specified as pod name of Kubernetes StatefulSet - pod-name-Num, where Num is a numeric part of pod name. See also -promscrape.cluster.memberLabel . See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more info (default "0")
-promscrape.cluster.memberURLTemplate string
   An optional template for URL to access vmagent instance with the given -promscrape.cluster.memberNum value. Every %d occurrence in the template is substituted with -promscrape.cluster.memberNum at urls to vmagent instances responsible for scraping the given target at /service-discovery page. For example -promscrape.cluster.memberURLTemplate='http://vmagent-%d:8429/targets'. See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more details
-promscrape.cluster.membersCount int
   The number of members in a cluster of scrapers. Each member must have a unique -promscrape.cluster.memberNum in the range 0 ... promscrape.cluster.membersCount-1 . Each member then scrapes roughly 1/N of all the targets. By default, cluster scraping is disabled, i.e. a single scraper scrapes all the targets. See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more info (default 1)
-promscrape.cluster.name string
   Optional name of the cluster. If multiple vmagent clusters scrape the same targets, then each cluster must have unique name in order to properly de-duplicate samples received from these clusters. See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more info
-promscrape.cluster.replicationFactor int
   The number of members in the cluster, which scrape the same targets. If the replication factor is greater than 1, then the deduplication must be enabled at remote storage side. See https://docs.victoriametrics.com/vmagent/#scraping-big-number-of-targets for more info (default 1)
-promscrape.config string
   Optional path to Prometheus config file with 'scrape_configs' section containing targets to scrape. The path can point to local file and to http url. See https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter for details
-promscrape.config.dryRun
   Checks -promscrape.config file for errors and unsupported fields and then exits. Returns non-zero exit code on parsing errors and emits these errors to stderr. See also -promscrape.config.strictParse command-line flag. Pass -loggerLevel=ERROR if you don't need to see info messages in the output.
-promscrape.config.strictParse
   Whether to deny unsupported fields in -promscrape.config . Set to false in order to silently skip unsupported fields (default true)
-promscrape.configCheckInterval duration
   Interval for checking for changes in -promscrape.config file. By default, the checking is disabled. See how to reload -promscrape.config file at https://docs.victoriametrics.com/vmagent/#configuration-update
-promscrape.consul.waitTime duration
   Wait time used by Consul service discovery. Default value is used if not set
-promscrape.consulSDCheckInterval duration
   Interval for checking for changes in Consul. This works only if consul_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#consul_sd_configs for details (default 30s)
-promscrape.consulagentSDCheckInterval duration
   Interval for checking for changes in Consul Agent. This works only if consulagent_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#consulagent_sd_configs for details (default 30s)
-promscrape.digitaloceanSDCheckInterval duration
   Interval for checking for changes in digital ocean. This works only if digitalocean_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#digitalocean_sd_configs for details (default 1m0s)
-promscrape.disableCompression
   Whether to disable sending 'Accept-Encoding: gzip' request headers to all the scrape targets. This may reduce CPU usage on scrape targets at the cost of higher network bandwidth utilization. It is possible to set 'disable_compression: true' individually per each 'scrape_config' section in '-promscrape.config' for fine-grained control
-promscrape.disableKeepAlive
   Whether to disable HTTP keep-alive connections when scraping all the targets. This may be useful when targets has no support for HTTP keep-alive connection. It is possible to set 'disable_keepalive: true' individually per each 'scrape_config' section in '-promscrape.config' for fine-grained control. Note that disabling HTTP keep-alive may increase load on both vmagent and scrape targets
-promscrape.discovery.concurrency int
   The maximum number of concurrent requests to Prometheus autodiscovery API (Consul, Kubernetes, etc.) (default 100)
-promscrape.discovery.concurrentWaitTime duration
   The maximum duration for waiting to perform API requests if more than -promscrape.discovery.concurrency requests are simultaneously performed (default 1m0s)
-promscrape.dnsSDCheckInterval duration
   Interval for checking for changes in dns. This works only if dns_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#dns_sd_configs for details (default 30s)
-promscrape.dockerSDCheckInterval duration
   Interval for checking for changes in docker. This works only if docker_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#docker_sd_configs for details (default 30s)
-promscrape.dockerswarmSDCheckInterval duration
   Interval for checking for changes in dockerswarm. This works only if dockerswarm_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#dockerswarm_sd_configs for details (default 30s)
-promscrape.dropOriginalLabels
   Whether to drop original labels for scrape targets at /targets and /api/v1/targets pages. This may be needed for reducing memory usage when original labels for big number of scrape targets occupy big amounts of memory. Note that this reduces debuggability for improper per-target relabeling configs
-promscrape.ec2SDCheckInterval duration
   Interval for checking for changes in ec2. This works only if ec2_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#ec2_sd_configs for details (default 1m0s)
-promscrape.eurekaSDCheckInterval duration
   Interval for checking for changes in eureka. This works only if eureka_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#eureka_sd_configs for details (default 30s)
-promscrape.fileSDCheckInterval duration
   Interval for checking for changes in 'file_sd_config'. See https://docs.victoriametrics.com/sd_configs/#file_sd_configs for details (default 1m0s)
-promscrape.gceSDCheckInterval duration
   Interval for checking for changes in gce. This works only if gce_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#gce_sd_configs for details (default 1m0s)
-promscrape.hetznerSDCheckInterval duration
   Interval for checking for changes in Hetzner API. This works only if hetzner_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#hetzner_sd_configs for details (default 1m0s)
-promscrape.httpSDCheckInterval duration
   Interval for checking for changes in http endpoint service discovery. This works only if http_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#http_sd_configs for details (default 1m0s)
-promscrape.kubernetes.apiServerTimeout duration
   How frequently to reload the full state from Kubernetes API server (default 30m0s)
-promscrape.kubernetes.attachNodeMetadataAll
   Whether to set attach_metadata.node=true for all the kubernetes_sd_configs at -promscrape.config . It is possible to set attach_metadata.node=false individually per each kubernetes_sd_configs . See https://docs.victoriametrics.com/sd_configs/#kubernetes_sd_configs
-promscrape.kubernetesSDCheckInterval duration
   Interval for checking for changes in Kubernetes API server. This works only if kubernetes_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#kubernetes_sd_configs for details (default 30s)
-promscrape.kumaSDCheckInterval duration
   Interval for checking for changes in kuma service discovery. This works only if kuma_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#kuma_sd_configs for details (default 30s)
-promscrape.maxDroppedTargets int
   The maximum number of droppedTargets to show at /api/v1/targets page. Increase this value if your setup drops more scrape targets during relabeling and you need investigating labels for all the dropped targets. Note that the increased number of tracked dropped targets may result in increased memory usage (default 10000)
-promscrape.maxResponseHeadersSize size
   The maximum size of http response headers from Prometheus scrape targets
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 4096)
-promscrape.maxScrapeSize size
   The maximum size of scrape response in bytes to process from Prometheus targets. Bigger responses are rejected
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 16777216)
-promscrape.minResponseSizeForStreamParse size
   The minimum target response size for automatic switching to stream parsing mode, which can reduce memory usage. See https://docs.victoriametrics.com/vmagent/#stream-parsing-mode
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 1000000)
-promscrape.noStaleMarkers
   Whether to disable sending Prometheus stale markers for metrics when scrape target disappears. This option may reduce memory usage if stale markers aren't needed for your setup. This option also disables populating the scrape_series_added metric. See https://prometheus.io/docs/concepts/jobs_instances/#automatically-generated-labels-and-time-series
-promscrape.nomad.waitTime duration
   Wait time used by Nomad service discovery. Default value is used if not set
-promscrape.nomadSDCheckInterval duration
   Interval for checking for changes in Nomad. This works only if nomad_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#nomad_sd_configs for details (default 30s)
-promscrape.openstackSDCheckInterval duration
   Interval for checking for changes in openstack API server. This works only if openstack_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#openstack_sd_configs for details (default 30s)
-promscrape.seriesLimitPerTarget int
   Optional limit on the number of unique time series a single scrape target can expose. See https://docs.victoriametrics.com/vmagent/#cardinality-limiter for more info
-promscrape.streamParse
   Whether to enable stream parsing for metrics obtained from scrape targets. This may be useful for reducing memory usage when millions of metrics are exposed per each scrape target. It is possible to set 'stream_parse: true' individually per each 'scrape_config' section in '-promscrape.config' for fine-grained control
-promscrape.suppressDuplicateScrapeTargetErrors
   Whether to suppress 'duplicate scrape target' errors; see https://docs.victoriametrics.com/vmagent/#troubleshooting for details
-promscrape.suppressScrapeErrors
   Whether to suppress scrape errors logging. The last error for each target is always available at '/targets' page even if scrape errors logging is suppressed. See also -promscrape.suppressScrapeErrorsDelay
-promscrape.suppressScrapeErrorsDelay duration
   The delay for suppressing repeated scrape errors logging per each scrape targets. This may be used for reducing the number of log lines related to scrape errors. See also -promscrape.suppressScrapeErrors
-promscrape.yandexcloudSDCheckInterval duration
   Interval for checking for changes in Yandex Cloud API. This works only if yandexcloud_sd_configs is configured in '-promscrape.config' file. See https://docs.victoriametrics.com/sd_configs/#yandexcloud_sd_configs for details (default 30s)
-pushmetrics.disableCompression
   Whether to disable request body compression when pushing metrics to every -pushmetrics.url
-pushmetrics.extraLabel array
   Optional labels to add to metrics pushed to every -pushmetrics.url . For example, -pushmetrics.extraLabel='instance="foo"' adds instance="foo" label to all the metrics pushed to every -pushmetrics.url
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-pushmetrics.header array
   Optional HTTP request header to send to every -pushmetrics.url . For example, -pushmetrics.header='Authorization: Basic foobar' adds 'Authorization: Basic foobar' header to every request to every -pushmetrics.url
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-pushmetrics.interval duration
   Interval for pushing metrics to every -pushmetrics.url (default 10s)
-pushmetrics.url array
   Optional URL to push metrics exposed at /metrics page. See https://docs.victoriametrics.com/#push-metrics . By default, metrics exposed at /metrics page aren't pushed to any remote storage
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-relabelConfig string
   Optional path to a file with relabeling rules, which are applied to all the ingested metrics. The path can point either to local file or to http url. See https://docs.victoriametrics.com/#relabeling for details. The config is reloaded on SIGHUP signal
-reloadAuthKey value
   Auth key for /-/reload http endpoint. It must be passed via authKey query arg. It overrides -httpAuth.*
   Flag value can be read from the given file when using -reloadAuthKey=file:///abs/path/to/file or -reloadAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -reloadAuthKey=http://host/path or -reloadAuthKey=https://host/path
-retentionFilter array
   Retention filter in the format 'filter:retention'. For example, '{env="dev"}:3d' configures the retention for time series with env="dev" label to 3 days. See https://docs.victoriametrics.com/#retention-filters for details. This flag is available only in VictoriaMetrics enterprise. See https://docs.victoriametrics.com/enterprise/
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-retentionPeriod value
   Data with timestamps outside the retentionPeriod is automatically deleted. The minimum retentionPeriod is 24h or 1d. See also -retentionFilter
   The following optional suffixes are supported: s (second), m (minute), h (hour), d (day), w (week), y (year). If suffix isn't set, then the duration is counted in months (default 1)
-retentionTimezoneOffset duration
   The offset for performing indexdb rotation. If set to 0, then the indexdb rotation is performed at 4am UTC time per each -retentionPeriod. If set to 2h, then the indexdb rotation is performed at 4am EET time (the timezone with +2h offset)
-search.cacheTimestampOffset duration
   The maximum duration since the current time for response data, which is always queried from the original raw data, without using the response cache. Increase this value if you see gaps in responses due to time synchronization issues between VictoriaMetrics and data sources. See also -search.disableAutoCacheReset (default 5m0s)
-search.disableAutoCacheReset
   Whether to disable automatic response cache reset if a sample with timestamp outside -search.cacheTimestampOffset is inserted into VictoriaMetrics
-search.disableCache
   Whether to disable response caching. This may be useful when ingesting historical data. See https://docs.victoriametrics.com/#backfilling . See also -search.resetRollupResultCacheOnStartup
-search.disableImplicitConversion
   Whether to return an error for queries that rely on implicit subquery conversions, see https://docs.victoriametrics.com/metricsql/#subqueries for details. See also -search.logImplicitConversion
-search.graphiteMaxPointsPerSeries int
   The maximum number of points per series Graphite render API can return (default 1000000)
-search.graphiteStorageStep duration
   The interval between datapoints stored in the database. It is used at Graphite Render API handler for normalizing the interval between datapoints in case it isn't normalized. It can be overridden by sending 'storage_step' query arg to /render API or by sending the desired interval via 'Storage-Step' http header during querying /render API (default 10s)
-search.ignoreExtraFiltersAtLabelsAPI
   Whether to ignore match[], extra_filters[] and extra_label query args at /api/v1/labels and /api/v1/label/.../values . This may be useful for decreasing load on VictoriaMetrics when extra filters match too many time series. The downside is that superfluous labels or series could be returned, which do not match the extra filters. See also -search.maxLabelsAPISeries and -search.maxLabelsAPIDuration
-search.latencyOffset duration
   The time when data points become visible in query results after the collection. It can be overridden on per-query basis via latency_offset arg. Too small value can result in incomplete last points for query results (default 30s)
-search.logImplicitConversion
   Whether to log queries with implicit subquery conversions, see https://docs.victoriametrics.com/metricsql/#subqueries for details. Such conversion can be disabled using -search.disableImplicitConversion
-search.logQueryMemoryUsage size
   Log query and increment vm_memory_intensive_queries_total metric each time the query requires more memory than specified by this flag. This may help detecting and optimizing heavy queries. Query logging is disabled by default. See also -search.logSlowQueryDuration and -search.maxMemoryPerQuery
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-search.logSlowQueryDuration duration
   Log queries with execution time exceeding this value. Zero disables slow query logging. See also -search.logQueryMemoryUsage (default 5s)
-search.maxConcurrentRequests int
   The maximum number of concurrent search requests. It shouldn't be high, since a single request can saturate all the CPU cores, while many concurrently executed requests may require high amounts of memory. See also -search.maxQueueDuration and -search.maxMemoryPerQuery (default 16)
-search.maxExportDuration duration
   The maximum duration for /api/v1/export call (default 720h0m0s)
-search.maxExportSeries int
   The maximum number of time series, which can be returned from /api/v1/export* APIs. This option allows limiting memory usage (default 10000000)
-search.maxFederateSeries int
   The maximum number of time series, which can be returned from /federate. This option allows limiting memory usage (default 1000000)
-search.maxGraphiteSeries int
   The maximum number of time series, which can be scanned during queries to Graphite Render API. See https://docs.victoriametrics.com/#graphite-render-api-usage (default 300000)
-search.maxGraphiteTagKeys int
   The maximum number of tag keys returned from Graphite API, which returns tags. See https://docs.victoriametrics.com/#graphite-tags-api-usage (default 100000)
-search.maxGraphiteTagValues int
   The maximum number of tag values returned from Graphite API, which returns tag values. See https://docs.victoriametrics.com/#graphite-tags-api-usage (default 100000)
-search.maxLabelsAPIDuration duration
   The maximum duration for /api/v1/labels, /api/v1/label/.../values and /api/v1/series requests. See also -search.maxLabelsAPISeries and -search.ignoreExtraFiltersAtLabelsAPI (default 5s)
-search.maxLabelsAPISeries int
   The maximum number of time series, which could be scanned when searching for the matching time series at /api/v1/labels and /api/v1/label/.../values. This option allows limiting memory usage and CPU usage. See also -search.maxLabelsAPIDuration, -search.maxTagKeys, -search.maxTagValues and -search.ignoreExtraFiltersAtLabelsAPI (default 1000000)
-search.maxLookback duration
   Synonym to -search.lookback-delta from Prometheus. The value is dynamically detected from interval between time series datapoints if not set. It can be overridden on per-query basis via max_lookback arg. See also '-search.maxStalenessInterval' flag, which has the same meaning due to historical reasons
-search.maxMemoryPerQuery size
   The maximum amounts of memory a single query may consume. Queries requiring more memory are rejected. The total memory limit for concurrently executed queries can be estimated as -search.maxMemoryPerQuery multiplied by -search.maxConcurrentRequests . See also -search.logQueryMemoryUsage
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-search.maxPointsPerTimeseries int
   The maximum points per a single timeseries returned from /api/v1/query_range. This option doesn't limit the number of scanned raw samples in the database. The main purpose of this option is to limit the number of per-series points returned to graphing UI such as VMUI or Grafana. There is no sense in setting this limit to values bigger than the horizontal resolution of the graph. See also -search.maxResponseSeries (default 30000)
-search.maxPointsSubqueryPerTimeseries int
   The maximum number of points per series, which can be generated by subquery. See https://valyala.medium.com/prometheus-subqueries-in-victoriametrics-9b1492b720b3 (default 100000)
-search.maxQueryDuration duration
   The maximum duration for query execution. It can be overridden on a per-query basis via 'timeout' query arg (default 30s)
-search.maxQueryLen size
   The maximum search query length in bytes
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 16384)
-search.maxQueueDuration duration
   The maximum time the request waits for execution when -search.maxConcurrentRequests limit is reached; see also -search.maxQueryDuration (default 10s)
-search.maxResponseSeries int
   The maximum number of time series which can be returned from /api/v1/query and /api/v1/query_range . The limit is disabled if it equals to 0. See also -search.maxPointsPerTimeseries and -search.maxUniqueTimeseries
-search.maxSamplesPerQuery int
   The maximum number of raw samples a single query can process across all time series. This protects from heavy queries, which select unexpectedly high number of raw samples. See also -search.maxSamplesPerSeries (default 1000000000)
-search.maxSamplesPerSeries int
   The maximum number of raw samples a single query can scan per each time series. This option allows limiting memory usage (default 30000000)
-search.maxSeries int
   The maximum number of time series, which can be returned from /api/v1/series. This option allows limiting memory usage (default 30000)
-search.maxSeriesPerAggrFunc int
   The maximum number of time series an aggregate MetricsQL function can generate (default 1000000)
-search.maxStalenessInterval duration
   The maximum interval for staleness calculations. By default, it is automatically calculated from the median interval between samples. This flag could be useful for tuning Prometheus data model closer to Influx-style data model. See https://prometheus.io/docs/prometheus/latest/querying/basics/#staleness for details. See also '-search.setLookbackToStep' flag
-search.maxStatusRequestDuration duration
   The maximum duration for /api/v1/status/* requests (default 5m0s)
-search.maxStepForPointsAdjustment duration
   The maximum step when /api/v1/query_range handler adjusts points with timestamps closer than -search.latencyOffset to the current time. The adjustment is needed because such points may contain incomplete data (default 1m0s)
-search.maxTSDBStatusSeries int
   The maximum number of time series, which can be processed during the call to /api/v1/status/tsdb. This option allows limiting memory usage (default 10000000)
-search.maxTagKeys int
   The maximum number of tag keys returned from /api/v1/labels . See also -search.maxLabelsAPISeries and -search.maxLabelsAPIDuration (default 100000)
-search.maxTagValueSuffixesPerSearch int
   The maximum number of tag value suffixes returned from /metrics/find (default 100000)
-search.maxTagValues int
   The maximum number of tag values returned from /api/v1/label/<label_name>/values . See also -search.maxLabelsAPISeries and -search.maxLabelsAPIDuration (default 100000)
-search.maxUniqueTimeseries int
   The maximum number of unique time series, which can be selected during /api/v1/query and /api/v1/query_range queries. This option allows limiting memory usage (default 300000)
-search.maxWorkersPerQuery int
   The maximum number of CPU cores a single query can use. The default value should work good for most cases. The flag can be set to lower values for improving performance of big number of concurrently executed queries. The flag can be set to bigger values for improving performance of heavy queries, which scan big number of time series (>10K) and/or big number of samples (>100M). There is no sense in setting this flag to values bigger than the number of CPU cores available on the system (default 16)
-search.minStalenessInterval duration
   The minimum interval for staleness calculations. This flag could be useful for removing gaps on graphs generated from time series with irregular intervals between samples. See also '-search.maxStalenessInterval'
-search.minWindowForInstantRollupOptimization value
   Enable cache-based optimization for repeated queries to /api/v1/query (aka instant queries), which contain rollup functions with lookbehind window exceeding the given value
   The following optional suffixes are supported: s (second), m (minute), h (hour), d (day), w (week), y (year). If suffix isn't set, then the duration is counted in months (default 3h)
-search.noStaleMarkers
   Set this flag to true if the database doesn't contain Prometheus stale markers, so there is no need in spending additional CPU time on its handling. Staleness markers may exist only in data obtained from Prometheus scrape targets
-search.queryStats.lastQueriesCount int
   Query stats for /api/v1/status/top_queries is tracked on this number of last queries. Zero value disables query stats tracking (default 20000)
-search.queryStats.minQueryDuration duration
   The minimum duration for queries to track in query stats at /api/v1/status/top_queries. Queries with lower duration are ignored in query stats (default 1ms)
-search.resetCacheAuthKey value
   Optional authKey for resetting rollup cache via /internal/resetRollupResultCache call
   Flag value can be read from the given file when using -search.resetCacheAuthKey=file:///abs/path/to/file or -search.resetCacheAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -search.resetCacheAuthKey=http://host/path or -search.resetCacheAuthKey=https://host/path
-search.resetRollupResultCacheOnStartup
   Whether to reset rollup result cache on startup. See https://docs.victoriametrics.com/#rollup-result-cache . See also -search.disableCache
-search.setLookbackToStep
   Whether to fix lookback interval to 'step' query arg value. If set to true, the query model becomes closer to InfluxDB data model. If set to true, then -search.maxLookback and -search.maxStalenessInterval are ignored
-search.treatDotsAsIsInRegexps
   Whether to treat dots as is in regexp label filters used in queries. For example, foo{bar=~"a.b.c"} will be automatically converted to foo{bar=~"a\\.b\\.c"}, i.e. all the dots in regexp filters will be automatically escaped in order to match only dot char instead of matching any char. Dots in ".+", ".*" and ".{n}" regexps aren't escaped. This option is DEPRECATED in favor of {__graphite__="a.*.c"} syntax for selecting metrics matching the given Graphite metrics filter
-selfScrapeInstance string
   Value for 'instance' label, which is added to self-scraped metrics (default "self")
-selfScrapeInterval duration
   Interval for self-scraping own metrics at /metrics page
-selfScrapeJob string
   Value for 'job' label, which is added to self-scraped metrics (default "victoria-metrics")
-smallMergeConcurrency int
   Deprecated: this flag does nothing
-snapshotAuthKey value
   authKey, which must be passed in query string to /snapshot* pages
   Flag value can be read from the given file when using -snapshotAuthKey=file:///abs/path/to/file or -snapshotAuthKey=file://./relative/path/to/file . Flag value can be read from the given http/https url when using -snapshotAuthKey=http://host/path or -snapshotAuthKey=https://host/path
-snapshotCreateTimeout duration
   Deprecated: this flag does nothing
-snapshotsMaxAge value
   Automatically delete snapshots older than -snapshotsMaxAge if it is set to non-zero duration. Make sure that backup process has enough time to finish the backup before the corresponding snapshot is automatically deleted
   The following optional suffixes are supported: s (second), m (minute), h (hour), d (day), w (week), y (year). If suffix isn't set, then the duration is counted in months (default 0)
-sortLabels
   Whether to sort labels for incoming samples before writing them to storage. This may be needed for reducing memory usage at storage when the order of labels in incoming samples is random. For example, if m{k1="v1",k2="v2"} may be sent as m{k2="v2",k1="v1"}. Enabled sorting for labels can slow down ingestion performance a bit
-storage.cacheSizeIndexDBDataBlocks size
   Overrides max size for indexdb/dataBlocks cache. See https://docs.victoriametrics.com/single-server-victoriametrics/#cache-tuning
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-storage.cacheSizeIndexDBIndexBlocks size
   Overrides max size for indexdb/indexBlocks cache. See https://docs.victoriametrics.com/single-server-victoriametrics/#cache-tuning
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-storage.cacheSizeIndexDBTagFilters size
   Overrides max size for indexdb/tagFiltersToMetricIDs cache. See https://docs.victoriametrics.com/single-server-victoriametrics/#cache-tuning
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-storage.cacheSizeStorageTSID size
   Overrides max size for storage/tsid cache. See https://docs.victoriametrics.com/single-server-victoriametrics/#cache-tuning
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 0)
-storage.maxDailySeries int
   The maximum number of unique series can be added to the storage during the last 24 hours. Excess series are logged and dropped. This can be useful for limiting series churn rate. See https://docs.victoriametrics.com/#cardinality-limiter . See also -storage.maxHourlySeries
-storage.maxHourlySeries int
   The maximum number of unique series can be added to the storage during the last hour. Excess series are logged and dropped. This can be useful for limiting series cardinality. See https://docs.victoriametrics.com/#cardinality-limiter . See also -storage.maxDailySeries
-storage.minFreeDiskSpaceBytes size
   The minimum free disk space at -storageDataPath after which the storage stops accepting new data
   Supports the following optional suffixes for size values: KB, MB, GB, TB, KiB, MiB, GiB, TiB (default 10000000)
-storageDataPath string
   Path to storage data (default "victoria-metrics-data")
-streamAggr.config string
   Optional path to file with stream aggregation config. See https://docs.victoriametrics.com/stream-aggregation/ . See also -streamAggr.keepInput, -streamAggr.dropInput and -streamAggr.dedupInterval
-streamAggr.dedupInterval duration
   Input samples are de-duplicated with this interval before optional aggregation with -streamAggr.config . See also -streamAggr.dropInputLabels and -dedup.minScrapeInterval and https://docs.victoriametrics.com/stream-aggregation/#deduplication
-streamAggr.dropInput
   Whether to drop all the input samples after the aggregation with -streamAggr.config. By default, only aggregated samples are dropped, while the remaining samples are stored in the database. See also -streamAggr.keepInput and https://docs.victoriametrics.com/stream-aggregation/
-streamAggr.dropInputLabels array
   An optional list of labels to drop from samples before stream de-duplication and aggregation . See https://docs.victoriametrics.com/stream-aggregation/#dropping-unneeded-labels
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-streamAggr.ignoreFirstIntervals int
   Number of aggregation intervals to skip after the start. Increase this value if you observe incorrect aggregation results after restarts. It could be caused by receiving unordered delayed data from clients pushing data into the database. See https://docs.victoriametrics.com/stream-aggregation/#ignore-aggregation-intervals-on-start
-streamAggr.ignoreOldSamples
   Whether to ignore input samples with old timestamps outside the current aggregation interval. See https://docs.victoriametrics.com/stream-aggregation/#ignoring-old-samples
-streamAggr.keepInput
   Whether to keep all the input samples after the aggregation with -streamAggr.config. By default, only aggregated samples are dropped, while the remaining samples are stored in the database. See also -streamAggr.dropInput and https://docs.victoriametrics.com/stream-aggregation/
-tls array
   Whether to enable TLS for incoming HTTP requests at the given -httpListenAddr (aka https). -tlsCertFile and -tlsKeyFile must be set if -tls is set. See also -mtls
   Supports array of values separated by comma or specified via multiple flags.
   Empty values are set to false.
-tlsAutocertCacheDir string
   Directory to store TLS certificates issued via Let's Encrypt. Certificates are lost on restarts if this flag isn't set. This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
-tlsAutocertEmail string
   Contact email for the issued Let's Encrypt TLS certificates. See also -tlsAutocertHosts and -tlsAutocertCacheDir .This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
-tlsAutocertHosts array
   Optional hostnames for automatic issuing of Let's Encrypt TLS certificates. These hostnames must be reachable at -httpListenAddr . The -httpListenAddr must listen tcp port 443 . The -tlsAutocertHosts overrides -tlsCertFile and -tlsKeyFile . See also -tlsAutocertEmail and -tlsAutocertCacheDir . This flag is available only in Enterprise binaries. See https://docs.victoriametrics.com/enterprise/
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-tlsCertFile array
   Path to file with TLS certificate for the corresponding -httpListenAddr if -tls is set. Prefer ECDSA certs instead of RSA certs as RSA certs are slower. The provided certificate file is automatically re-read every second, so it can be dynamically updated. See also -tlsAutocertHosts
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-tlsCipherSuites array
   Optional list of TLS cipher suites for incoming requests over HTTPS if -tls is set. See the list of supported cipher suites at https://pkg.go.dev/crypto/tls#pkg-constants
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-tlsKeyFile array
   Path to file with TLS key for the corresponding -httpListenAddr if -tls is set. The provided key file is automatically re-read every second, so it can be dynamically updated. See also -tlsAutocertHosts
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-tlsMinVersion array
   Optional minimum TLS version to use for the corresponding -httpListenAddr if -tls is set. Supported values: TLS10, TLS11, TLS12, TLS13
   Supports an array of values separated by comma or specified via multiple flags.
   Value can contain comma inside single-quoted or double-quoted string, {}, [] and () braces.
-usePromCompatibleNaming
   Whether to replace characters unsupported by Prometheus with underscores in the ingested metric names and label names. For example, foo.bar{a.b='c'} is transformed into foo_bar{a_b='c'} during data ingestion if this flag is set. See https://prometheus.io/docs/concepts/data_model/#metric-names-and-labels
-version
   Show VictoriaMetrics version
-vmalert.proxyURL string
   Optional URL for proxying requests to vmalert. For example, if -vmalert.proxyURL=http://vmalert:8880 , then alerting API requests such as /api/v1/rules from Grafana will be proxied to http://vmalert:8880/api/v1/rules
-vmui.customDashboardsPath string
   Optional path to vmui dashboards. See https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/app/vmui/packages/vmui/public/dashboards
-vmui.defaultTimezone string
   The default timezone to be used in vmui. Timezone must be a valid IANA Time Zone. For example: America/New_York, Europe/Berlin, Etc/GMT+3 or Local
```

