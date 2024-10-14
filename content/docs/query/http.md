---
title: 查询 API
weight: 5
---

## Prometheus 查询接口 {#single-prometheus}

### Instant Query（即时查询） {#instant-query}

Instant Query 在指定的时间点上执行查询：
```
GET | POST /api/v1/query?query=...&time=...&step=...&timeout=...
```

参数：

- `query` - MetricsQL 查询语句.
- `time` - 可选，以秒为精度来执行查询。如果省略，时间将设置为`now()`(当前时间戳)。`time`参数可以用[多种允许的格式]({{< relref "./_index.md#timestamp" >}})指定。
- `step` - 可选，在执行查询时，用于在过去搜索原始样本的[间隔](https://prometheus.io/docs/prometheus/latest/querying/basics/#time-durations)（当在指定时间缺少样本时使用）。例如，请求 `/api/v1/query?query=up&step=1m` 会在 `now()` 和 `now()-1m` 之间的间隔内查找指标`up`的最近写入的数据点。如果省略，`step` 默认设置为`5m`(5分钟)。
- `timeout` - 可选，查询超时时间。例如，`timeout=5s` 会在`5s`后取消请求。默认的超时时间会使用系统参数`-search.maxQueryDuration`指定的值。 该参数在单机版 VictoriaMetrics 和 vmselect 组件都有支持。

The result of Instant query is a list of time series matching the filter in query expression. Each returned series contains exactly one (timestamp, value) entry, where timestamp equals to the time query arg, while the value contains query result at the requested time.

即时查询的结果是一个符合查询表达式中过滤条件的[时间序列]({{< relref "concepts.md#timeseries" >}})列表。每个返回的序列都包含一个（时间戳，值）条目，其中时间戳等于查询参数中的时间，而值包含请求时间的查询结果。

要了解即时查询的工作原理，让我们从一个原始数据样本开始：

```
foo_bar 1.00 1652169600000 # 2022-05-10 10:00:00
foo_bar 2.00 1652169660000 # 2022-05-10 10:01:00
foo_bar 3.00 1652169720000 # 2022-05-10 10:02:00
foo_bar 5.00 1652169840000 # 2022-05-10 10:04:00, 丢了 1 个数据点
foo_bar 5.50 1652169960000 # 2022-05-10 10:06:00, 丢了 1 个数据点
foo_bar 5.50 1652170020000 # 2022-05-10 10:07:00
foo_bar 4.00 1652170080000 # 2022-05-10 10:08:00
foo_bar 3.50 1652170260000 # 2022-05-10 10:11:00, 丢了 2 个数据点
foo_bar 3.25 1652170320000 # 2022-05-10 10:12:00
foo_bar 3.00 1652170380000 # 2022-05-10 10:13:00
foo_bar 2.00 1652170440000 # 2022-05-10 10:14:00
foo_bar 1.00 1652170500000 # 2022-05-10 10:15:00
foo_bar 4.00 1652170560000 # 2022-05-10 10:16:00
```

上面的数据包含了`foo_bar`时间序列的样本列表，样本之间的时间间隔从 1m 到 3m 不等。如果我们将这个数据样本绘制在图表上，它将具有以下形式：

![](https://docs.victoriametrics.com/keyconcepts/data_samples.webp)

To get the value of the foo_bar series at some specific moment of time, for example 2022-05-10 10:03:00, in VictoriaMetrics we need to issue an instant query：
为了获取`foo_bar`这个时间序列在特定时间的数值，比如`2022-05-10 10:03:00`，在 VictoriaMetrics 中我们使用即时查询：

```sh
curl "http://<victoria-metrics-addr>/api/v1/query?query=foo_bar&time=2022-05-10T10:03:00.000Z"
```

```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "foo_bar"
        },
        "value": [
          1652169780, // 2022-05-10 10:03:00
          "3"
        ]
      }
    ]
  }
}
```
作为返回值，VictoriaMetrics 返回了一个值为 3 的 (时间戳, 样本值) 数据，表示在给定时间`2022-05-10 10:03:00` 的 `foo_bar` 序列。但是，如果我们再次查看原始数据样本，会发现`2022-05-10 10:03:00` 并没有原始样本数据。当请求的时间戳没有原始样本时，，VictoriaMetrics 会尝试找到请求时间戳之前最近的样本：

![](https://docs.victoriametrics.com/keyconcepts/instant_query.webp)

The time range in which VictoriaMetrics will try to locate a replacement for a missing data sample is equal to 5m by default and can be overridden via the step parameter.

Instant queries can return multiple time series, but always only one data sample per series. Instant queries are used in the following scenarios:

- Getting the last recorded value;
- For rollup functions such as count_over_time;
- For alerts and recording rules evaluation;
- Plotting Stat or Table panels in Grafana.

VictoriaMetrics 尝试寻找缺失样本数据替代品的时间范围默认是`5m`(5分钟)，可以通过`step`参数自定义。

即时查询可以返回多个时间序列，但每个序列始终只有一个数据样本。即时查询用于以下场景：

- 获取最后写入的值；
- 用于`count_over_time`等汇总函数；
- 用于警报规则；
- 在 Grafana 中绘制 Stat 或 Table 面板。

### Range Query
Range query executes the query expression at the given [start…end] time range with the given step:

```
GET | POST /api/v1/query_range?query=...&start=...&end=...&step=...&timeout=...
```

Params:

- query - MetricsQL expression.
- start - the starting timestamp of the time range for query evaluation.
- end - the ending timestamp of the time range for query evaluation. If the end isn’t set, then the end is automatically set to the current time.
- step - the interval between data points, which must be returned from the range query. The query is executed at start, start+step, start+2*step, …, end timestamps. If the step isn’t set, then it default to 5m (5 minutes).
- timeout - optional query timeout. For example, timeout=5s. Query is canceled when the timeout is reached. By default the timeout is set to the value of -search.maxQueryDuration command-line flag passed to single-node VictoriaMetrics or to vmselect component in VictoriaMetrics cluster.

The result of Range query is a list of time series matching the filter in query expression. Each returned series contains (timestamp, value) results for the query executed at start, start+step, start+2*step, …, end timestamps. In other words, Range query is an Instant query executed independently at start, start+step, …, end timestamps.

For example, to get the values of foo_bar during the time range from 2022-05-10 09:59:00 to 2022-05-10 10:17:00, we need to issue a range query:

```sh
curl "http://<victoria-metrics-addr>/api/v1/query_range?query=foo_bar&step=1m&start=2022-05-10T09:59:00.000Z&end=2022-05-10T10:17:00.000Z"
```

```json
{
  "status": "success",
  "data": {
    "resultType": "matrix",
    "result": [
      {
        "metric": {
          "__name__": "foo_bar"
        },
        "values": [
          [
            1652169600,
            "1"
          ],
          [
            1652169660,
            "2"
          ],
          [
            1652169720,
            "3"
          ],
          [
            1652169780,
            "3"
          ],
          [
            1652169840,
            "7"
          ],
          [
            1652169900,
            "7"
          ],
          [
            1652169960,
            "7.5"
          ],
          [
            1652170020,
            "7.5"
          ],
          [
            1652170080,
            "6"
          ],
          [
            1652170140,
            "6"
          ],
          [
            1652170260,
            "5.5"
          ],
          [
            1652170320,
            "5.25"
          ],
          [
            1652170380,
            "5"
          ],
          [
            1652170440,
            "3"
          ],
          [
            1652170500,
            "1"
          ],
          [
            1652170560,
            "4"
          ],
          [
            1652170620,
            "4"
          ]
        ]
      }
    ]
  }
}
```

In response, VictoriaMetrics returns 17 sample-timestamp pairs for the series foo_bar at the given time range from 2022-05-10 09:59:00 to 2022-05-10 10:17:00. But, if we take a look at the original data sample again, we’ll see that it contains only 13 raw samples. What happens here is that the range query is actually an instant query executed 1 + (start-end)/step times on the time range from start to end. If we plot this request in VictoriaMetrics the graph will be shown as the following:

![](https://docs.victoriametrics.com/keyconcepts/range_query.webp)

The blue dotted lines in the figure are the moments when the instant query was executed. Since the instant query retains the ability to return replacements for missing points, the graph contains two types of data points: real and ephemeral. ephemeral data points always repeat the closest raw sample that occurred before (see red arrow on the pic above).

This behavior of adding ephemeral data points comes from the specifics of the pull model:

- Metrics are scraped at fixed intervals.
- Scrape may be skipped if the monitoring system is overloaded.
- Scrape may fail due to network issues.

According to these specifics, the range query assumes that if there is a missing raw sample then it is likely a missed scrape, so it fills it with the previous raw sample. The same will work for cases when step is lower than the actual interval between samples. In fact, if we set step=1s for the same request, we’ll get about 1 thousand data points in response, where most of them are ephemeral.

Sometimes, the lookbehind window for locating the datapoint isn’t big enough and the graph will contain a gap. For range queries, lookbehind window isn’t equal to the step parameter. It is calculated as the median of the intervals between the first 20 raw samples in the requested time range. In this way, VictoriaMetrics automatically adjusts the lookbehind window to fill gaps and detect stale series at the same time.

Range queries are mostly used for plotting time series data over specified time ranges. These queries are extremely useful in the following scenarios:

- Track the state of a metric on the given time interval;
- Correlate changes between multiple metrics on the time interval;
- Observe trends and dynamics of the metric change.

#### Query 延时

By default, Victoria Metrics does not immediately return the recently written samples. Instead, it retrieves the last results written prior to the time specified by the -search.latencyOffset command-line flag, which has a default offset of 30 seconds. This is true for both query and query_range and may give the impression that data is written to the VM with a 30-second delay.

This flag prevents from non-consistent results due to the fact that only part of the values are scraped in the last scrape interval.

Here is an illustration of a potential problem when -search.latencyOffset is set to zero:

![](https://docs.victoriametrics.com/keyconcepts/without_latencyOffset.webp)

When this flag is set, the VM will return the last metric value collected before the -search.latencyOffset duration throughout the -search.latencyOffset duration:

![](https://docs.victoriametrics.com/keyconcepts/with_latencyOffset.webp)

It can be overridden on per-query basis via latency_offset query arg.

VictoriaMetrics buffers recently ingested samples in memory for up to a few seconds and then periodically flushes these samples to disk. This bufferring improves data ingestion performance. The buffered samples are invisible in query results, even if -search.latencyOffset command-line flag is set to 0, or if latency_offset query arg is set to 0. You can send GET request to /internal/force_flush http handler at single-node VictoriaMetrics or to vmstorage at cluster version of VictoriaMetrics in order to forcibly flush the buffered samples to disk, so they become visible for querying. The /internal/force_flush handler is provided for debugging and testing purposes only. Do not call it in production, since this may significantly slow down data ingestion performance and increase resource usage.

VictoriaMetrics 支持下面这些 [Prometheus 查询 API](https://prometheus.io/docs/prometheus/latest/querying/api/):

+ [/api/v1/query](https://docs.victoriametrics.com/keyConcepts.html#instant-query)
+ [/api/v1/query_range](https://docs.victoriametrics.com/keyConcepts.html#range-query)
+ [/api/v1/series](https://prometheus.io/docs/prometheus/latest/querying/api/#finding-series-by-label-matchers)
+ [/api/v1/labels](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names)
+ [/api/v1/label/…/values](https://prometheus.io/docs/prometheus/latest/querying/api/#querying-label-values)
+ [/api/v1/status/tsdb](https://prometheus.io/docs/prometheus/latest/querying/api/#tsdb-stats). See [these docs](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#tsdb-stats) for details.
+ [/api/v1/targets](https://prometheus.io/docs/prometheus/latest/querying/api/#targets) - see [these docs](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-scrape-prometheus-exporters-such-as-node-exporter) for more details.
+ [/federate](https://prometheus.io/docs/prometheus/latest/federation/) - see [these docs](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#federation) for more details.

这些接口可以被Prometheus兼容的客户端（如Grafana或curl）查询。所有Prometheus查询API处理程序都可以使用`/prometheus`前缀进行查询。例如，`/prometheus/api/v1/query`和`/api/v1/query`都可以正常工作。

#### 查询优化
+ VictoriaMetrics 接受`extra_label=<label_name>=<label_value>`查询参数（可选），可以用于强制使用额外 Label 过滤器执行查询。例如，`/api/v1/query_range?extra_label=user_id=123&extra_label=group_id=456&query=<query>`会自动将`{user_id="123",group_id="456"}`Label 过滤器添加到给定的查询中。此功能可用于限制给定租户可见的 timeseries 范围。一般`extra_label`查询参数由位于 VictoriaMetrics 前面的查询代理服务自动设置。例如，可以参考使用 [vmauth](https://docs.victoriametrics.com/vmauth.html) 和 [vmgateway](https://docs.victoriametrics.com/vmgateway.html) 作为查询代理的示例。
+ VictoriaMetrics 接受`extra_filters[]=series_selector`查询参数（可选），可用于对查询强制执行任意的 Label 过滤器。例如，`/api/v1/query_range?extra_filters[]={env=~"prod|staging",user="xyz"}&query=<query>`将自动将`{env=~"prod|staging",user="xyz"}`Label 过滤器添加到给定的查询中。此功能可用于限制给定租户可见的 timeseries 范围。我们建议在 VictoriaMetrics 前面的查询代理自动设置`extra_filters[]`查询参数。您可以将[vmauth](https://docs.victoriametrics.com/vmauth.html)和[vmgateway](https://docs.victoriametrics.com/vmgateway.html)作为这种代理的示例。
+ VictoriaMetrics 接受多种格式的 `time`，`start` 和 `end` 查询参数，可参考[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#timestamp-formats)。
+ VictoriaMetrics对于[/api/v1/query](https://docs.victoriametrics.com/keyConcepts.html#instant-query)和[/api/v1/query_range](https://docs.victoriametrics.com/keyConcepts.html#range-query)接口支持`round_digits`查询参数。它可用于指定返回的指标值的保留小数点位数。例如，`/api/v1/query?query=avg_over_time(temperature[1h])&round_digits=2`会将让返回的指标值保留小数点后面 2 位。
+ VictoriaMetrics允许在[/api/v1/labels](https://docs.victoriametrics.com/url-examples.html#apiv1labels)和[/api/v1/label/<labelName>/values](https://docs.victoriametrics.com/url-examples.html#apiv1labelvalues)接口中使用`limit`查询参数来限制返回的条目数量。例如，对`/api/v1/labels?limit=5`的查询请求最多返回5个唯一的 Label 值，并忽略其他 Label。如果提供的`limit`值超过了相应的`-command-line`命令行参数`-search.maxTagKeys`或`-search.maxTagValues`，则会使用命令行参数中指定的限制。
+ 默认情况下，VictoriaMetrics从[/api/v1/series](https://docs.victoriametrics.com/url-examples.html#apiv1series)、[/api/v1/labels](https://docs.victoriametrics.com/url-examples.html#apiv1labels)和[/api/v1/label/<labelName>/values](https://docs.victoriametrics.com/url-examples.html#apiv1labelvalues)返回最近一天从00:00 UTC开始的 series 数据，而Prometheus API默认返回所有时间的数据。如果要选择特定的时间范围的 series 数据，可使用 `start` 和 `end` 参数指定。由于性能优化的考虑，VictoriaMetrics会将指定的 `start..end` 时间范围舍入到天的粒度。如果您需要在给定时间范围内获取精确的 Label 集合，请将查询发送到[/api/v1/query](https://docs.victoriametrics.com/keyConcepts.html#instant-query)或[/api/v1/query_range](https://docs.victoriametrics.com/keyConcepts.html#range-query)。
+ VictoriaMetrics在[/api/v1/series](https://docs.victoriametrics.com/url-examples.html#apiv1series)中接受`limit`查询参数，用于限制返回的条目数量。例如，对`/api/v1/series?limit=5`的查询将最多返回5个 series，并忽略其余的时间序列。如果提供的`limit`值超过了相应的命令行参数`-search.maxSeries`的值，则会使用命令行中指定的限制。
+ 此外，VictoriaMetrics还提供了以下接口：
    - `/vmui` - 基本的 Web UI 界面，阅读[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#vmui)。 
    - `/api/v1/series/count` - 返回数据库中 time series 的总数量。注意：
        * 该接口扫描了整个数据库的倒排索引，所以如果数据库包含数千万个 series 时间序列，它可能会变慢。
        * 该接口可能把[删除 time series](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-delete-time-series) 计算在内，这是内部实现导致的。
    - `/api/v1/status/active_queries` - 返回当前正在执行的查询。
    - `/api/v1/status/top_queries` - 返回下面几个查询列表:
        * 执行最频繁的查询列表 - `topByCount`
        * 平均执行时间最长的查询列表 - `topByAvgDuration`
        * 执行时间最长的查询列表 - `topBySumDuration`
        * 返回的查询个数可以使用 `topN` 参数进行限制。历史查询可以使用 `maxLifetime` 参数过滤掉。比如，请求`/api/v1/status/top_queries?topN=5&maxLifetime=30s`返回最近 30 秒内每个类型的 Top5 个查询列表。VictoriaMetrics 会跟踪统计最近`-s earch.queryStats.lastQueriesCount`时间内，且执行时间大于`search.queryStats.minQueryDuration`的查询。

#### Timestamp 格式
VictoriaMetrics 接受下面这些格式的 `time`, `start` and `end` 参数， 在 [query APIs](https://docs.victoriametrics.com/#prometheus-querying-api-usage) 和 [export APIs](https://docs.victoriametrics.com/#how-to-export-time-series) 中皆是如此。

+ **Unix 秒级时间戳**，float 类型，小数部分代表的是毫秒。比如，`1562529662.678`。
+ **Unix 毫秒级时间戳**。比如，`1562529662678`。
+ [**RFC3339**](https://www.ietf.org/rfc/rfc3339.txt)。比如， `2022-03-29T01:02:03Z` or `2022-03-29T01:02:03+02:30`.
+ **RFC3339 的省略格式**。比如：`2022`, `2022-03`, `2022-03-29`, `2022-03-29T01`, `2022-03-29T01:02`, `2022-03-29T01:02:03`。该 RFC3339 格式默认是使用 UTC 时区的。可以使用 `+hh:mm` or `-hh:mm` 后缀来指定时区。比如，`2022-03-01+06:30` 代表 `2022-03-01` 是 `06:30` 时区。
+ **基于当前时间的相对时间**。比如，`1h5m`, `-1h5m`或 `now-1h5m` 均代表 1小时5分钟之前，这里的 now 表示当前时间。

### Graphite API
VictoriaMetrics支持Graphite协议的数据摄入——详见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-graphite-compatible-agents-such-as-statsd)。VictoriaMetrics支持以下Graphite查询API，这些API对于Grafana中的[Graphite数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/)是必需的：

+ Render API - 看 [这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-render-api-usage)。
+ Metrics API - 看 [这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-render-api-usage)。
+ Tags API - 看 [这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-render-api-usage)。

所有Graphite处理程序都可以使用`/graphite`前缀。例如，`/graphite/metrics/find`和`/metrics/find`都应该有效。

VictoriaMetrics接受可选查询参数：`extra_label=<标签名>=<标签值>`和`extra_filters[]=series_selector`，这些参数适用于所有Graphite API。这些参数可用于限制给定租户可见的时间序列范围。预计`extra_label`查询参数将由位于VictoriaMetrics前方的身份验证代理自动设置。[vmauth](https://www.victoriametrics.com.cn/victoriametrics/xi-tong-zu-jian/vmauth)和[vmgateway](https://docs.victoriametrics.com/vmgateway.html)是此类代理的示例。

VictoriaMetrics支持`__graphite__`伪标签，用于在[MetricsQL](https://docs.victoriametrics.com/MetricsQL.html)中使用与Graphite兼容的过滤器过滤时间序列。详见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#selecting-graphite-metrics)。

#### Graphite Render API 用法
VictoriaMetrics在`/render` url 上支持[Graphite Render API](https://graphite.readthedocs.io/en/stable/render_api.html)子集，Grafana中的Graphite数据源会使用这一功能。在Grafana中配置[Graphite数据源](https://grafana.com/docs/grafana/latest/datasources/graphite/)时，必须将`Storage-Step` HTTP请求头设置为VictoriaMetrics中存储的Graphite数据点之间的步长。例如，`Storage-Step: 10s`表示VictoriaMetrics中存储的Graphite数据点之间相隔10秒。

#### Graphite Metrics API 用法
VictoriaMetrics 支持 [Graphite Metrics API](https://graphite-api.readthedocs.io/en/latest/api.html#the-metrics-api) 中的一下接口：

+ [/metrics/find](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find)
+ [/metrics/expand](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand)
+ [/metrics/index.json](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json)

VictoriaMetrics `/metrics/find` 和 `/metrics/expand`接口上支持以下额外的参数:

+ `label` - 用于选择任意标签值。默认情况下，`label=__name__`，即选择度量名称。
+ `delimiter` - 用于在度量名称层次结构中使用不同的分隔符。例如，`/metrics/find?delimiter=``&query=node``*` 将返回所有以`node_`开头的度量名称前缀。默认情况下，`delimiter=.`。

#### Graphite Tags API usage
VictoriaMetrics 支持下面这些 [Graphite Tags API](https://graphite.readthedocs.io/en/stable/tags.html):

+ [/tags/tagSeries](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb)
+ [/tags/tagMultiSeries](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb)
+ [/tags](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
+ [/tags/{tag_name}](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
+ [/tags/findSeries](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags)
+ [/tags/autoComplete/tags](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
+ [/tags/autoComplete/values](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support)
+ [/tags/delSeries](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb)

## 集群版
集群版本和[单机版](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben)的API接口主要区别是数据的读取和写入是由独立组件完成的，而且也有了租户的支持。集群版本也支持`/prometheus/api/v1`来接收 `jsonl`, `csv`, `native` 和 `prometheus`数据格式，而不仅仅是`prometheus`数据格式。可以在[这里](https://docs.victoriametrics.com/url-examples.html)查看VictoriaMetrics的API的使用范例。

### [Prometheus 查询 API](https://prometheus.io/docs/prometheus/latest/querying/api/)
`http://<vmselect>:8481/select/<accountID>/prometheus/<suffix>`, 其中:

+ `<accountID>` 是一个任意32位数字，用来标识查询的空间（即租户）。
+ `<suffix>` 可以是一下的内容：
    - `api/v1/query` - 执行 [PromQL instant](https://docs.victoriametrics.com/keyConcepts.html#instant-query).
    - `api/v1/query_range` - 执行 [PromQL range 查询](https://docs.victoriametrics.com/keyConcepts.html#range-query)。
    - `api/v1/series` - 执行 [series 查询](https://prometheus.io/docs/prometheus/latest/querying/api/#finding-series-by-label-matchers)。
    - `api/v1/labels` - 返回 [label 名称列表](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names)。
    - `api/v1/label/<label_name>/values` - 返回指定 `<label_name>` 的所有值，参考[这个 API](https://prometheus.io/docs/prometheus/latest/querying/api/#querying-label-values).
    - `federate` - 返回 [federated metrics](https://prometheus.io/docs/prometheus/latest/federation/).
    - `api/v1/export` - 导出 JSON line 格式的原始数据，更多信息看[这篇文章](https://medium.com/@valyala/analyzing-prometheus-data-with-external-tools-5f3e5e147639)。
    - `api/v1/export/native` - 导出原生二进制格式的原始数据，该数据可以通过另一个接口`api/v1/import/native`导入到 VictoriaMetrics (见上文).
    - `api/v1/export/csv` - 导出 CSV 格式原始数据。它可以使用另外一个接口 `api/v1/import/csv` 导入到 VictoriaMetrics（见上文）。
    - `api/v1/series/count` - 返回 series 的总数。
    - `api/v1/status/tsdb` - 返回时序数据的统计信息。更多详细信息见[这些文档](https://docs.victoriametrics.com/#tsdb-stats)。
    - `api/v1/status/active_queries` - 返回当前活跃的查询请求。逐一每个 `vmselect` 实例都有独立的活跃查询列表。
    - `api/v1/status/top_queries` - 返回执行频率最高以及查询耗时最长的查询列表。
    - `metric-relabel-debug` - 用于对 [relabeling 规则](https://docs.victoriametrics.com/relabeling.html) Debug。

### [Graphite Metrics API](https://graphite-api.readthedocs.io/en/latest/api.html#the-metrics-api)
`http://<vmselect>:8481/select/<accountID>/graphite/<suffix>`, 其中:

+ `<accountID>`
+ 是一个任意32位数字，用来标识查询的空间（即租户）。
+ `<suffix>` 可以是一下的内容：
    - `render` - 实现 Graphite Render API. 看 [these docs](https://graphite.readthedocs.io/en/stable/render_api.html).
    - `metrics/find` - 搜索 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find).
    - `metrics/expand` - 扩展 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand).
    - `metrics/index.json` - returns 所有的 names. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json).
    - `tags/tagSeries` - 注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).
    - `tags/tagMultiSeries` - 批量注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).
    - `tags` - 返回 tag 名称列表. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
    - `tags/<tag_name>` - 返回指定 `<tag_name>`的值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
    - `tags/findSeries` - 返回匹配`expr`的 series，[these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
    - `tags/autoComplete/tags` - 返回匹配 `tagPrefix` 和/或 `expr`的tag名称列表。 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
    - `tags/autoComplete/values` - 返回匹配 `valuePrefix` 和/或 `expr` tag值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
    - `tags/delSeries` - deletes series matching the given `path`. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb).

