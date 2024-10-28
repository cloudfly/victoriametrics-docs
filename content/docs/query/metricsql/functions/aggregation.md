---
title: 聚合统计
date: 2024-10-28T14:33:16+08:00
keywords:
- metricsql
- aggregation
- any
- avg
- topk
- bottomk
- limitk 
- max
- min
- median
- count
description: MetricsQL 支持的聚合函数列表及介绍，比如 sum，avg 等等
weight: 3
---

**聚合函数** 对 [Rollup 结果]({{< relref "./rollup.md" >}})中的多个 timeseries 进行合并聚合计算。

其他细节：
+ 默认情况下，将所有 timeseries 聚合到一组里（即聚合后得到一个 timeseries）。可以通过在`by`和`without`修饰符中指定分组 Label 来进行多组聚合。例如，`count(up) by (job)` 会按 `job` Label 值对[汇总结果]({{< relref "./rollup.md" >}})进行分组，并对每个组独立进行[count](#count)计算，而`count(up) without (instance)`会在计算[count](#count)聚合之前，按除`instance`之外的所有 Label 对[汇总结果]({{< relref "./rollup.md" >}})进行分组。可以在`by`和`without`修饰符中放置多个Label。
+ 如果聚合函数直接应用于[series_selector]({{< relref "../../../concepts.md#filtering" >}})，则在计算聚合之前会自动应用[default_rollup()]({{< relref "./rollup.md#default_rollup" >}})函数。例如，`count(up)`会被隐式转换为`count(default_rollup(up))`。
+ 聚合函数可以接受任意数量的参数。例如，`avg(q1, q2, q3)` 会将 `q1`、`q2` 和 `q3` 返回的时间序列合并在一块计算平均值。
+ 聚合函数支持`limit N`后缀，可用于限制输出 timeseries 数量。例如，`sum(x) by (y) limit 3` 将聚合的 timeseries 数量限制为 3。所有其他 timeseries 将被忽略。
  - 注意，`limit N`并不会改善重查询，前面的聚合语句还是会多所有数据做全量查询和计算，只是在最终返回结果时值取`N`个结果。常见的场景是用于缓解 Grafana 的渲染压力，大量的数据点可能会导致 Grafana 页面崩溃。

另请参见[隐式查询转换]({{< relref "../_index.md#conversion" >}})。

支持的聚合函数列表：

### any
`any(q) by (group_labels)` 从`q`返回的 timeseries 中，根据 `group_labels` 返回任意一个 timeseries。

另请参阅 [group](#group)。

### avg
`avg(q) by (group_labels)` 根据 `group_labels` 返回的 timeseries 的平均值。该聚合是针对每组具有相同时间戳的数据点单独计算的。

此函数 PromQL 也支持。

### bottomk
`bottomk(k, q)`返回`q`返回的所有 timeseries 中值最小的 `k` 个 timeseries。该聚合是针对每组具有相同时间戳的数据点单独计算的。

此函数 PromQL 也支持。

另请参阅 [topk](#topk)、[bottomk_min](#bottomk_min) 和 [bottomk_last](#bottomk_last)。

### bottomk_avg
`bottomk_avg(k, q, "other_label=other_value")`返回`q`中平均值最小的`k`个 timeseries。如果设置了可选参数`other_label=other_value`，则返回具有给定Label 的剩余 timeseries 总和。例如，`bottomk_avg(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最多`3`条平均值最小的 timeseries，加上一个带有 `{job="other"}` Label 的 timeseries 时间序列，该 series 包含剩余序列的总和（如果有的话）。

另请参阅 [topk_avg](#topk_avg)。

### bottomk_last
`bottomk_last(k, q, "other_label=other_value")`返回`q`中最后值最小的`k`个 timeseries。如果设置了可选参数 `other_label=other_value`，则返回具有给定 Label 的剩余 timeseries的总和。例如，`bottomk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最多`3`个最大值最小的timeseries，加上一个带有`{job="other"}`Label的 timeseries，该 series 包含剩余序列的总和（如果有的话）。

另请参阅 [topk_last](#topk_last)。

### bottomk_max
`bottomk_max(k, q, "other_label=other_value")`返回`q`中最大值最小的`k`个 timeseries。如果设置了可选参数 `other_label=other_value`，则返回具有给定 Label 的剩余 timeseries 的总和。例如，`bottomk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最多`3`个最大值最小的 timeseries ，加上一个带有 `{job="other"}` 标签的 timeseries ，该 series 包含剩余序列的总和（如果有的话）。

另请参阅 [topk_max](#topk_max)。

### bottomk_median
`bottomk_median(k, q, "other_label=other_value")`返回`q`中中位数最小的最多 `k` 个 timeseries 。如果设置了可选参数 `other_label=other_value`，则返回具有给定标签的剩余 timeseries 的总和。例如，`bottomk_median(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最多`3`个中位数最小的 timeseries ，加上一个带有 `{job="other"}` 标签的 timeseries ，该序列包含剩余序列的总和（如果有的话）。

另请参阅 [topk_median](#topk_median)。

### bottomk_min
`bottomk_min(k, q, "other_label=other_value")`返回`q`中最小值最小的最多 `k` 个 timeseries 。如果设置了可选参数 `other_label=other_value`，则返回具有给定标签的剩余 timeseries 的总和。例如，`bottomk_min(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最多`3`个最小值最小的 timeseries ，加上一个带有 `{job="other"}` 标签的 timeseries ，该序列包含剩余序列的总和（如果有的话）。

另请参阅 [topk_min](#topk_min)。

### count
`count(q) by (group_labels)`返回`q`返回的 timeseries 中每个`group_labels`的非空点的数量。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### count_values
`count_values("label", q)`计算具有相同值的点的数量，并将计数存储在一个带有额外`label`的 timeseries 中，该 Label 包含每个初始值。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

另请参阅 [count_values_over_time]({{< relref "./rollup.md#count_values_over_time" >}}) 和 [label_match]({{< relref "./label.md#label_match" >}})。

### distinct
`distinct(q)`计算每组具有相同时间戳的点的唯一值的数量。类似于 SQL 中的`COUNT(DISTINCT(value))`

另请参阅 [distinct_over_time]({{< relref "./rollup.md#distinct_over_time" >}})。

### geomean
`geomean(q)`计算每组具有相同时间戳的点的几何平均值。

### group
`group(q) by (group_labels)`为`q`返回的 timeseries 中每个`group_labels`返回值恒为`1`的timeseries。

此函数 PromQL 也支持。另请参阅 [any](#any)。

### histogram
`histogram(q)`计算每组具有相同时间戳的点的 [VictoriaMetrics 直方图](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350)。对于通过热图可视化大量 timeseries 时非常有用。更多详情请参阅[这篇文章](https://medium.com/@valyala/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350)。

另请参阅 [histogram_over_time]({{< relref "./rollup.md#histogram_over_time" >}}) 和 [histogram_quantile]({{< relref "./rollup.md#histogram_quantile" >}})。

### limitk
`limitk(k, q) by (group_labels)`从`q`返回的 timeseries 中为每个`group_labels`挑选最多 `k` 个 timeseries 返回。返回的时间序列集在多次调用中保持不变。

另请参阅 [limit_offset](#limit_offset)。

### mad
`mad(q) by (group_labels)` 计算`q`返回的所有 timeseries 中每个 `group_labels` 的[中位数绝对偏差](https://en.wikipedia.org/wiki/Median_absolute_deviation)。该聚合是针对每组具有相同时间戳的点单独计算的。

另请参阅 [range_mad](#range_mad)、[mad_over_time]({{< relref "./rollup.md#mad_over_time" >}})、[outliers_mad](#outliers_mad) 和 [stddev](#stddev)。

### max
`max(q) by (group_labels)`为`q`返回的所有 timeseries 中每个`group_labels`统计出最大值。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### median
`median(q) by (group_labels)`为`q`返回的所有 timeseries 中每个 `group_labels`统计出中位数。该聚合是针对每组具有相同时间戳的点单独计算的。

### min
`min(q) by (group_labels)`为`q`返回的所有 timeseries 中每个 `group_labels`统计出最小值。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### mode
`mode(q) by (group_labels)`为`q`返回的所有 timeseries 中每个`group_labels`计算出[众数](https://en.wikipedia.org/wiki/Mode_(statistics))。该聚合是针对每组具有相同时间戳的点单独计算的。

### quantile
`quantile(phi, q) by (group_labels)`计算`q`返回的所有 timeseries 中每个`group_labels`的`phi`分位数。`phi`必须在`[0...1]`范围内。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

另请参阅 [quantiles](#quantiles) 和 [histogram_quantile](#histogram_quantile)。

### quantiles
`quantiles("phiLabel", phi1, ..., phiN, q)`计算`q`返回的所有 timeseries 中的`phi*`分位数，并将它们返回在带有`{phiLabel="phi*"}`Label的 timeseries 中。`phi*`必须在`[0...1]`范围内。该聚合是针对每组具有相同时间戳的点单独计算的。

另请参阅 [quantile](#quantile)。

### share
`share(q) by (group_labels)`返回`q`返回的每个时间戳的每个非负点的份额，范围为`[0..1]`，结果中每个`group_labels`的份额总和等于 1。

此函数对于将[直方图桶]({{< relref "concepts.md#histogram" >}})份额归一化到`[0..1]`范围内非常有用：

```plain {filename=MetricsQL}
share(
  sum(
    rate(http_request_duration_seconds_bucket[5m])
  ) by (le, vmrange)
)
```
另请参阅 [range_normalize](#range_normalize)。

### stddev
`stddev(q) by (group_labels)`计算`q`返回的所有 timeseries 中每个 `group_labels` 的标准偏差。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### stdvar
`stdvar(q) by (group_labels)`计算`q`返回的所有 timeseries 中每个 `group_labels` 的标准方差。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### sum
`sum(q) by (group_labels)`返回`q`返回的所有 timeseries 中每个 `group_labels` 的总和。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

### sum2
`sum2(q) by (group_labels)`计算`q`返回的所有 timeseries 中每个 `group_labels` 的平方和。该聚合是针对每组具有相同时间戳的点单独计算的。

### topk
`topk(k, q)`返回`q`返回的所有 timeseries 中值最大的前`k`个点。该聚合是针对每组具有相同时间戳的点单独计算的。

此函数 PromQL 也支持。

另请参阅 [bottomk](#bottomk)、[topk_max](#topk_max) 和 [topk_last](#topk_last)。

### topk_avg
`topk_avg(k, q, "other_label=other_value")`返回`q`中**平均值**最大的前`k`个时间序列。如果设置了可选的`other_label=other_value`参数，则返回带有给定 Label 的剩余 timeseries 的总和。例如，`topk_avg(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回平均值最大的前`3`个 timeseries，和一个带有 `{job="other"}` Label 的 timeseries，其中包含剩余序列的总和（如果有的话）。

另请参阅 [bottomk_avg](#bottomk_avg)。

### topk_last
`topk_last(k, q, "other_label=other_value")`返回`q`中**最后值**最大的前`k`个时间序列。如果设置了可选的`other_label=other_value`参数，则返回带有给定标签的剩余 timeseries 的总和。例如，`topk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最大值最大的前`3`个 timeseries，加上一个带有`{job="other"}` Label 的 timeseries，其中包含剩余序列的总和（如果有的话）。

另请参阅 [bottomk_last](#bottomk_last)。

### topk_max
`topk_max(k, q, "other_label=other_value")`返回`q`中**最大值**最大的前`k`个时间序列。如果设置了可选的`other_label=other_value`参数，则返回带有给定标签的剩余 timeseries 的总和。例如，`topk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` 将返回最大值最大的前`3`个 timeseries ，加上一个带有`{job="other"}` Label 的 timeseries，其中包含剩余序列的总和（如果有的话）。

另请参阅 [bottomk_max](#bottomk_max)。

### topk_median
`topk_median(k, q, "other_label=other_value")`返回 `q` 中**中位数**最大的前`k`个时间序列。如果设置了可选的`other_label=other_value`参数，则返回带有给定标签的剩余 timeseries 的总和。例如，`topk_median(3, sum(process_resident_memory_bytes) by (job), "job=other")`将返回中位数最大的前`3`个时间序列，加上一个带有`{job="other"}` Label 的 timeseries，其中包含剩余序列的总和（如果有的话）。

另请参阅 [bottomk_median](https://docs.victoriametrics.com/metricsql/#bottomk_median)。

### topk_min
`topk_min(k, q, "other_label=other_value")`返回`q`中**最小值**最大的前`k`个时间序列。如果设置了可选的`other_label=other_value`参数，则返回带有给定标签的剩余 timeseries 的总和。例如，`topk_min(3, sum(process_resident_memory_bytes) by (job), "job=other")`将返回最小值最大的前`3`个时间序列，加上一个带有`{job="other"}` Label 的 timeseries，其中包含剩余序列的总和（如果有的话）。

另请参阅 [bottomk_min](https://docs.victoriametrics.com/metricsql/#bottomk_min)。

### zscore
`zscore(q) by (group_labels)`返回 `q` 返回的所有 timeseries 中每个 `group_labels` 的[z-score](https://en.wikipedia.org/wiki/Standard_score) 值。该聚合是针对每组具有相同时间戳的点单独计算的。此函数对于检测相关时间序列组中的异常值非常有用。

另请参阅 [zscore_over_time]({{< relref "./rollup.md#zscore_over_time" >}})、[range_trim_zscore]({{< relref "./transmit.md#range_trim_zscore" >}})。