---
title: 查询 API
weight: 5
---

同[写入API]({{< relref "../write/api.md" >}})一样，集群版本和单机版的查询API主要区别是数据的查询是由独立组件完成的，并有多租户的支持。
集群版的 URL 格式为 `http://<vmselect>:8481/select/<accountID>/prometheus/<suffix>`, 其中:

- `<accountID>` 是一个任意32位数字，用来标识查询的空间（即租户），详见[这里]({{< relref "../write/api.md" >}})。
- `<suffix>` 见下面。

## 导出数据 {#export}

### /api/v1/export

导出 JSON line 格式的原始数据，更多信息看[这篇文章](https://medium.com/@valyala/analyzing-prometheus-data-with-external-tools-5f3e5e147639)。

导出的数据可以使用另外一个接口 `api/v1/import/csv` 导入到 VictoriaMetrics。

{{< tabs items="单机版,集群版" >}}
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

### /api/v1/export/csv

导出 CSV 格式原始数据。它可以使用另外一个接口 `api/v1/import/csv` 导入到 VictoriaMetrics。

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

## Prometheus {#prometheus}

VictoriaMetrics 支持下面这些 [Prometheus 查询 API](https://prometheus.io/docs/prometheus/latest/querying/api/):

### [/api/v1/query](https://docs.victoriametrics.com/keyConcepts.html#instant-query)

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

### [/api/v1/query_range](https://docs.victoriametrics.com/keyConcepts.html#range-query)

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
### [/api/v1/status/tsdb](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-stats)

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

更多详细内容看[这里](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#tsdb-stats)。

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

返回当前活跃的查询请求。逐一每个 `vmselect` 实例都有独立的活跃查询列表。
{{< tabs items="单机版,集群版" >}}
  {{< tab >}}
  ```sh
  curl http://localhost:8428/prometheus/api/v1/status/active_queries
  ```
  {{< /tab >}}
  {{< tab >}}
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


### [/api/v1/targets](https://prometheus.io/docs/prometheus/latest/querying/api/#targets)

更多详情看[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-scrape-prometheus-exporters-such-as-node-exporter)。

### [/federate](https://prometheus.io/docs/prometheus/latest/federation/)

更多详情看[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#federation)

## Graphite
VictoriaMetrics支持Graphite协议的数据摄入——详见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-graphite-compatible-agents-such-as-statsd)。VictoriaMetrics支持以下Graphite查询API，这些API对于Grafana中的[Graphite数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/)是必需的：

所有Graphite处理程序都可以使用`/graphite`前缀。例如，`/graphite/metrics/find`和`/metrics/find`都应该有效。

VictoriaMetrics支持`__graphite__`伪标签，用于在[MetricsQL](./metricsql/_index.md)中使用与Graphite兼容的过滤器过滤时间序列。详见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#selecting-graphite-metrics)。

### Render API {#graphite-render}
VictoriaMetrics在`/render` url 上支持[Graphite Render API](https://graphite.readthedocs.io/en/stable/render_api.html)子集，Grafana中的Graphite数据源会使用这一功能。在Grafana中配置[Graphite数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/)时，必须将`Storage-Step` HTTP请求头设置为VictoriaMetrics中存储的Graphite数据点之间的步长。例如，`Storage-Step: 10s`表示VictoriaMetrics中存储的Graphite数据点之间相隔10秒。

### Metrics API {#graphite-metrics}
VictoriaMetrics 支持 [Graphite Metrics API](https://graphite-api.readthedocs.io/en/latest/api.html#the-metrics-api) 中的一下接口：

#### /metrics/find
+ [/metrics/find](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find)
搜索 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find).
#### /metrics/expand
+ [/metrics/expand](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand)
扩展 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand).
#### /metrics/index.json
+ [/metrics/index.json](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json)
 returns 所有的 names. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json).

VictoriaMetrics `/metrics/find` 和 `/metrics/expand`接口上支持以下额外的参数:

+ `label` - 用于选择任意标签值。默认情况下，`label=__name__`，即选择度量名称。
+ `delimiter` - 用于在度量名称层次结构中使用不同的分隔符。例如，`/metrics/find?delimiter=``&query=node``*` 将返回所有以`node_`开头的度量名称前缀。默认情况下，`delimiter=.`。

### Tags API {#graphite-tags}
VictoriaMetrics 支持下面这些 [Graphite Tags API](https://graphite.readthedocs.io/en/stable/tags.html):

#### /tags/tagSeries
注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).

#### /tags/tagMultiSeries
+ [/tags/tagMultiSeries](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb)
批量注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).

#### /tags
+ [/tags](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回 tag 名称列表. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).

#### /tags/{tag_name}
+ [/tags/{tag_name}](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回指定 `<tag_name>`的值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).

#### /tags/findSeries
+ [/tags/findSeries](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
返回匹配`expr`的 series，[these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).

#### /tags/autoComplete/tags
+ [/tags/autoComplete/tags](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
返回匹配 `tagPrefix` 和/或 `expr`的tag名称列表。 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
#### /tags/autoComplete/values
+ [/tags/autoComplete/values](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
返回匹配 `valuePrefix` 和/或 `expr` tag值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
#### /tags/delSeries
+ [/tags/delSeries](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb)

deletes series matching the given `path`. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb).
