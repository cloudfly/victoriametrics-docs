---
title: 查询 API
date: 2024-11-03T11:01:45+08:00
description: VictoriaMetrics 的数据查询 API 接口文档说明和样例，方便进行日常参考。
weight: 5
---

同[写入 API]({{< relref "../write/api.md" >}}) 一样，集群版本和单机版的查询API主要区别是查询功能是由独立组件 vmselect 完成的，并支持多租户。
集群版的 URL 格式为`http://<vmselect>:8481/select/<accountID>/prometheus/<suffix>`, 其中:

- `<accountID>`是一个任意`int32`数字，用来标识查询的空间（即租户），详见[这里]({{< relref "../write/api.md" >}})。
- `<suffix>`见下面。

## 导出数据 {#export}

### /api/v1/export

导出 JSON line 格式的原始样本，更多信息看[这篇文章](https://medium.com/@valyala/analyzing-prometheus-data-with-external-tools-5f3e5e147639)。

导出的数据可以使用另外一个接口`/api/v1/import`导入到 VictoriaMetrics。

{{< tabs items="单机版,集群版,指定时间范围,Gzip压缩" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/api/v1/export -d 'match[]=vm_http_request_errors_total' > filename.json
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/export -d 'match[]=vm_http_request_errors_total' > filename.json
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/api/v1/export -d 'match[]=<timeseries_selector_for_export>' -d 'start=1654543486' -d 'end=1654543486'
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl -H 'Accept-Encoding: gzip' http://localhost:8428/api/v1/export -d 'match[]=<timeseries_selector_for_export>' -d 'start=2022-06-06T19:25:48' -d 'end=2022-06-06T19:29:07' data.jsonl.gz
  ```
  {{< /tab >}}

{{< /tabs >}}

### /api/v1/export/native

导出原生二进制格式的原始数据，该数据可以通过另一个接口`api/v1/import/native`导入到 VictoriaMetrics。

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/api/v1/export/native -d 'match[]=vm_http_request_errors_total' > filename.bin
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/export/native -d 'match[]=vm_http_request_errors_total' > filename.bin
  ```
  {{< /tab >}}
{{< /tabs >}}

在大型数据库上，您可能会遇到导出时间序列数量限制的问题。在这种情况下，您需要调整`-search.maxExportSeries`启动参数：

```sh
# count unique time series in database
wget -O- -q 'http://your_victoriametrics_instance:8428/api/v1/series/count' | jq '.data[0]'

# relaunch victoriametrics with search.maxExportSeries more than value from previous command
```

同上面`/api/v1/export`接口一样，可使用`start`和`end`请求参数，来限制导出数据的时间范围。

native 格式导出的数据不会应用[去重操作]({{< relref "../ops/single.md#deduplication" >}})。预期是在数据导入过程中进行去重处理。

### /api/v1/export/csv

导出 CSV 格式原始数据。它可以使用另外一个接口`api/v1/import/csv`导入到 VictoriaMetrics。

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/api/v1/export/csv -d 'format=__name__,__value__,__timestamp__:unix_s' -d 'match[]=vm_http_request_errors_total' > filename.csv
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/export/csv -d 'format=__name__,__value__,__timestamp__:unix_s' -d 'match[]=vm_http_request_errors_total' > filename.csv
  ```
  {{< /tab >}}
{{< /tabs >}}


CSV 格式导出的数据会被[去重]({{< relref "../ops/single.md#deduplication" >}})。使用`reduce-memory-usage=1`请求参数关闭去重。

## Prometheus {#prometheus}

VictoriaMetrics 支持下面这些 [Prometheus 查询 API](https://prometheus.io/docs/prometheus/latest/querying/api/):

### [/api/v1/query]({{< relref "./_index.md#instant-query" >}})

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/query -d 'query=vm_http_request_errors_total'
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/query -d 'query=vm_http_request_errors_total'
  ```
  {{< /tab >}}
{{< /tabs >}}

### [/api/v1/query_range]({{< relref "./_index.md#range-query" >}})

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/query_range -d 'query=sum(increase(vm_http_request_errors_total{job="foo"}[5m]))' -d 'start=-1d' -d 'step=1h'
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/query_range -d 'query=sum(increase(vm_http_request_errors_total{job="foo"}[5m]))' -d 'start=-1d' -d 'step=1h'
  ```
  {{< /tab >}}
{{< /tabs >}}

### [/api/v1/series](https://prometheus.io/docs/prometheus/latest/querying/api/#finding-series-by-label-matchers)

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/series -d 'match[]=vm_http_request_errors_total'
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/series -d 'match[]=vm_http_request_errors_total'
  ```
  {{< /tab >}}
{{< /tabs >}}

### [/api/v1/labels](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names)

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/labels
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/labels
  ```
  {{< /tab >}}
{{< /tabs >}}

### [/api/v1/label/{name}/values](https://prometheus.io/docs/prometheus/latest/querying/api/#querying-label-values)

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/label/job/values
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/label/job/values
  ```
  {{< /tab >}}
{{< /tabs >}}

## DB 状态

### [/api/v1/status/tsdb](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-stats) {#tsdb-stats}

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/status/tsdb
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/status/tsdb
  ```
  {{< /tab >}}
{{< /tabs >}}

VictoriaMetrics 在`/api/v1/status/tsdb`接口上的信息统计方式类似于 Prometheus，具体参见[这些 Prometheus 文档](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-stats)。

该接口支持以下参数，所有参数均可选：

- `topN=N`：表示返回统计值最大的`N`条数据，默认`N=10`，即返回top10的统计信息数据。
- `date=YYYY-MM-DD`：这里`YYYY-MM-DD`表示用于统计哪天的数据。默认统计当天的数据，使用`date=1970-01-01`表示统计全局的数据。
- `focusLabel=LABEL_NAME`：在返回数据中的`seriesCountByFocusLabelValue`字段中，计算给定`LABEL_NAME`中包含 timeseries 最多的 Label Value 集合。
- `match[]=SELECTOR`：这里`SELECTOR`用来限定统计目标，只有匹配了该过滤器的 timeseries 才会被统计，默认统计所有的 timeseries。
- `extra_label=LABEL=VALUE`：使用`LABEL=VALUE`过滤出要统计的目标 timeseries；该参数用于简单过滤场景，计算速度要比`match[]`参数快。

在[集群版]({{< relref "../ops/cluster.md" >}})中，每个`vmstorage`独立存储的时间序列。`vmselect`通过`/api/v1/status/tsdb`API 从每个`vmstorage`节点请求统计信息，并通过对每个时间序列的统计信息求和来合并结果。
当同一时间序列的样本数据由于[多副本]({{< relref "../ops/cluster.md#replication" >}})或[重路由]({{< relref "../ops/cluster.md#cluster-available" >}})机制分布在多个`vmstorage`节点上时，可能会导致统计结果变大。
比如你的集群是`3`副本，统计值大概率是写入数据量的`3`倍。


### /api/v1/series/count

返回 series 的总数。

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/series/count
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/series/count
  ```
  {{< /tab >}}
{{< /tabs >}}

### /api/v1/status/active_queries

返回当前活跃的查询请求。
{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/status/active_queries
  ```
  {{< /tab >}}
  {{< tab >}}
  每个`vmselect`实例都有独立的活跃查询列表，如果你要获取整个集群的，就要遍历所有的`vmselect`实例。
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/status/active_queries
  ```
  {{< /tab >}}
{{< /tabs >}}

### /api/v1/status/top_queries

返回执行频率最高以及查询耗时最长的查询列表。

{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/status/top_queries
  ```
  {{< /tab >}}
  {{< tab >}}
  ```sh
  curl http://<vmselect>:8481/select/0/prometheus/api/v1/status/top_queries
  ```
  {{< /tab >}}
{{< /tabs >}}


### /admin/tenants

列出在给定时间范围内已写入数据的租户，仅集群版支持该 API 。

```
http://<vmselect>:8481/admin/tenants?start=...&end=...`
```

`start`和`end`参数是可选的。默认返回 VictoriaMetrics 集群中至少包含一条数据的租户列表。


## Graphite
VictoriaMetrics 支持 Graphite 协议的数据写入，详见[这些文档]({{< relref "../write/api.md#graphite" >}})。也支持以下 Graphite 查询 API，这些 API 对于平替掉 Grafana 中的 [Graphite数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/) 是必需的：

所有 Graphite API 都可以使用`/graphite`前缀。例如，`/graphite/metrics/find`和`/metrics/find`都应该有效。

VictoriaMetrics 支持`__graphite__`伪 Label，用处是在 [MetricsQL]({{< relref "./metricsql/_index.md" >}}) 中使用与 Graphite 兼容的过滤器。详见[这些文档]({{< relref "../query/metricsql/_index.md#graphite-filter" >}})。

### [Render API](https://graphite.readthedocs.io/en/stable/render_api.html) {#graphite-render}
VictoriaMetrics在`/render`接口上只做了部分支持，Grafana 中的 Graphite 数据源会使用这个接口。
在 Grafana中 配置 [Graphite 数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/)时，必须将`Storage-Step`HTTP 请求头设置成 VictoriaMetrics 中存储的 Graphite 数据样本粒度。
例如，`Storage-Step: 10s`表示 VictoriaMetrics 中存储的 Graphite 数据点之间相隔是 10 秒。

### [Metrics API](https://graphite-api.readthedocs.io/en/latest/api.html#the-metrics-api) {#graphite-metrics}

#### [/metrics/find](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find)
搜索 Graphite metrics.

#### [/metrics/expand](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand)
扩展 Graphite metrics

#### [/metrics/index.json](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json)
返回所有的指标名称.

VictoriaMetrics `/metrics/find`和`/metrics/expand`接口上额外支持了以下参数:

+ `label`- 用于选择任意 Label Name。默认情况下，`label=__name__`，即选择 Metric 名称。
+ `delimiter`- 用于在 Metric 名称层次结构中使用不同的分隔符。例如，`/metrics/find?delimiter=_&query=node*`将返回所有名称以`node_`开头的 Metric 。默认情况下，`delimiter=.`。

### [Tags API](https://graphite.readthedocs.io/en/stable/tags.html) {#graphite-tags}

#### [/tags/tagSeries](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb)
注册 time series。

#### [/tags/tagMultiSeries](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb)

批量注册 time series.

#### [/tags](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回 tag 名称列表.

#### [/tags/{tag_name}](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回指定`<tag_name>`的值列表.

#### [/tags/findSeries](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回匹配`expr`的 series.

#### [/tags/autoComplete/tags](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
返回匹配`tagPrefix`和/或`expr`的tag名称列表。

#### [/tags/autoComplete/values](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
返回匹配`valuePrefix`和/或`expr`tag值列表。

#### [/tags/delSeries](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb)

删除成功匹配参数`path`的 timeseries.
