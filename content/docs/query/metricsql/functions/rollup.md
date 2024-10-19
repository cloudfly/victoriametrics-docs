---
title: 汇总（Rollup）
description: MetricsQL 支持的 rollup 类函数列表及介绍，比如 rate，increase 等等
weight: 1
---

## 什么是Rollup
Rollup函数（也称为范围函数或窗口函数）在所选 timeseries 的给定回溯窗口上对原始样本的汇总计算。例如，`avg_over_time(temperature[24h])`计算过去 24 小时内所有原始样本的平均温度值。

更多细节：

+ 如果在Grafana中使用`rollup`函数来构建图形，那么每个点上的`rollup`都是独立计算的。例如，`avg_over_time(temperature[24h])`图表中的每个点显示了截止到该时间点的过去24小时内的平均温度。点之间的间隔由Grafana传递给`/api/v1/query_range`接口作为`step`查询参数设置。
+ 如果给定的查询语句返回多个 timeseries，则每个返回的序列都会单独计算汇总。
+ 如果方括号中的回溯窗口缺失，则MetricsQL会自动将回溯窗口设置为图表上点之间的间隔（即`/api/v1/query_range`中的`step`查询参数，Grafana中的`$__interval`值或MetricsQL中的`1i`持续时间）。例如，`rate(http_requests_total)`在Grafana中等同于`rate(http_requests_total[$__interval])`。它也等同于`rate(http_requests_total[1i])`。
+ 每个在MetricsQL中的系列选择器都必须包装在一个rollup函数中。否则，它会自动被包装成`default_rollup`。例如，`foo{bar="baz"}`在执行计算之前会自动转换为`default_rollup(foo{bar="baz"}[1i])`。
+ 如果在rollup函数中传递的参数不是series selector，那么内部的参数会自动转换为[子查询]({{< relref "../_index.md#subquery" >}})。
+ 所有的汇总函数都接受可选的`keep_metric_names`修饰符。如果设置了该修饰符，函数将在结果中保留指标名称。请参阅[这些文档]({{< relref "../_index.md#keeping-metric-name" >}})。

更多参见[隐式查询转换]({{< relref "../_index.md#conversion" >}})。

此外一些 Rollup 函数与 Prometheus 的实现逻辑有一定的差异，详细内容请阅读[这篇文档]({{< relref "../_index.md#better-rate" >}})


## 函数列表
### absent_over_time
`absent_over_time(series_selector[d])`是一个 rollup 函数，如果给定的向前窗口`d`不包含原始样本，则返回1。否则，它将返回一个空结果。 

这个函数在PromQL中得到支持。

{{< doc-see-other present_over_time >}}

### aggr_over_time
`aggr_over_time(("rollup_func1", "rollup_func2", ...), series_selector[d])`计算给定回溯窗口`d`上所有列出的`rollup_func* `对原始样本进行汇总。根据给定的series_selector，对每个返回的时间序列进行单独计算。

`rollup_func*`可以是任意一个 rollup 函数。比如，`aggr_over_time(("min_over_time", "max_over_time", "rate"), m[d])`就会对`m[d]`计算 [min_over_time](#min_over_time), [max_over_time](#max_over_time) 和 [rate](#rate) 。

### ascent_over_time
`ascent_over_time(series_selector[d])`计算给定时间窗口d上原始样本值的上升。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

该功能用于在GPS跟踪中跟踪高度增益。{{< doc-keep-metric-name >}}

{{< doc-see-other descent_over_time >}}

### avg_over_time
`avg_over_time(series_selector[d])`计算给定时间窗口d上原始样本值的平均值。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

这个函数在 PromQL 中也支持，{{< doc-see-other median_over_time >}}

### changes
`changes(series_selector[d])`计算给定时间窗口d上原始样本值的变化。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

不像 Prometheus里的`changes()`，它考虑了给定时间窗口 d 中最后一个样本的变化，详情请参阅[这篇文章](https://medium.com/@romanhavronenko/victoriametrics-promql-compliance-d4318203f51e)。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持，{{< doc-see-other changes_prometheus >}}

### changes_prometheus
`changes_prometheus(series_selector[d])`计算时间窗口 d 中原始样本值变化的次数。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

它不考虑在时间窗口 d 之前的最后一个样本值的变化，这和 Prometheus 的逻辑是一样的。详情请参阅[这篇文章](https://medium.com/@romanhavronenko/victoriametrics-promql-compliance-d4318203f51e)。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持，{{< doc-see-other changes >}}

### count_eq_over_time
`count_eq_over_time(series_selector[d], eq)`计算时间窗口 d 中原始样本值等于`eq`的个数。它针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}
{{< doc-see-other count_over_time >}}

### count_gt_over_time
`count_gt_over_time(series_selector[d], gt)`计算时间窗口 d 中原始样本值大于`gt`的个数。它针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other count_over_time >}}

### count_le_over_time
`count_le_over_time(series_selector[d], le)`计算时间窗口 d 中原始样本值小于`lt`的个数。它针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other count_over_time >}}

### count_ne_over_time
`count_ne_over_time(series_selector[d], ne)`计算时间窗口 d 中原始样本值不等于`ne`的个数。它针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other count_over_time >}}

### count_over_time
`count_over_time(series_selector[d])`计算时间窗口 d 中原始样本值的个数。它针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持，{{< doc-see-other count_le_over_time >}}

### decreases_over_time
`decreases_over_time(series_selector[d])`计算给定时间窗口d上原始样本值的下降值。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other increases_over_time >}}

### default_rollup
`default_rollup(series_selector[d])`返回给定时间窗口d中最后一个原始样本。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

### delta
`delta(series_selector[d])`is a [rollup function](#rollup-functions), 

计算给定回溯窗口 d 之前的最后一个样本和该窗口的最后一个样本的差异。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

MetricsQL中`delta()`函数的计算逻辑和 Prometheus 中的 delta() 函数计算逻辑存在轻微差异，详情看[这里]({{< relref "../_index.md#diff" >}})。

{{< doc-keep-metric-name >}}

该函数 PromQL 也支持. {{< doc-see-other increase >}}

### delta_prometheus
`delta_prometheus(series_selector[d])`计算回溯窗口中第一个样本和最后一个样本的差异。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。

`delta_prometheus()`的计算逻辑和 Prometheus `delta()`一致。 详情看[这里]({{< relref "../_index.md#diff" >}})。

{{< doc-keep-metric-name >}}

另请参见 [delta](#delta)。

### deriv
`deriv(series_selector[d])`计算给定回溯窗口 d 中时序数据的每秒导数。针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。该导数使用线性回归计算。

{{< doc-keep-metric-name >}}

该函数 PromQL 也支持. {{< doc-see-other deriv_fast >}}

### deriv_fast
`deriv_fast(series_selector[d])`使用给定回溯窗口 d 中第一个和最后一个 raw sample 来计算每秒导数。针对[series_selector]({{< relref "../basic.md#filtering" >}})查询返回的每个时间序列单独执行计算。该导数使用线性回归计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other deriv >}}

### descent_over_time
`descent_over_time(series_selector[d])`计算给定回溯窗口 d 中 raw sample 值的下降量。针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询查询返回的每个时间序列单独执行计算。

这个功能对于追踪GPS定位中的海拔高度损失非常有用。

{{< doc-keep-metric-name >}}

{{< doc-see-other ascent_over_time >}}

### distinct_over_time
`distinct_over_time(series_selector[d])`返回给定回溯窗口 d 中 [raw sample]({{< relref "concepts.md#sample" >}}) 值的种类数。针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other count_values_over_time >}}

### duration_over_time
`duration_over_time(series_selector[d], max_interval)`<font style="color:rgb(6, 6, 7);">返回给定的 </font>[series_selector]({{< relref "concepts.md#filtering" >}}) <font style="color:rgb(6, 6, 7);">返回的时间序列在给定的回溯窗口</font>`<font style="color:rgb(6, 6, 7);">d</font>`<font style="color:rgb(6, 6, 7);">内存在的持续时间，以秒为单位。预期每个序列相邻样本之间的间隔不超过</font>`<font style="color:rgb(6, 6, 7);">max_interval</font>`<font style="color:rgb(6, 6, 7);">。否则，这样的间隔被忽略不计。</font>

{{< doc-keep-metric-name >}}

另请参见 [lifetime](#lifetime) 和 [lag](#lag)。

### first_over_time
`first_over_time(series_selector[d])`返回给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内的第一个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 值。

另请参见 [last_over_time](#last_over_time) 和 [tfirst_over_time](#tfirst_over_time)。

### geomean_over_time
`geomean_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 值的[geometric mean](https://en.wikipedia.org/wiki/Geometric_mean)。

{{< doc-keep-metric-name >}}

这个函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})。

### histogram_over_time
`histogram_over_time(series_selector[d])`对给定的回溯窗口`d`中的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 计算 [VictoriaMetrics histogram](https://godoc.org/github.com/VictoriaMetrics/metrics#Histogram)。针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询查询返回的每个时间序列单独执行计算。其计算出来的histograms 可被用来传递给[histogram_quantile](#histogram_quantile)，用于计算多个[gauges]({{< relref "concepts.md#gauge" >}})指标的分位值。比如，下面的语句计算每个国家过去 24 小时的温度中位数：

`histogram_quantile(0.5, sum(histogram_over_time(temperature[24h])) by (vmrange,country))`。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})。

### holt_winters
`holt_winters(series_selector[d], sf, tf)`使用平滑因子`sf`和趋势因子`tf`对给定回溯窗口`d`中的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 计算 Holt-Winters（通过[double exponential smoothing](https://en.wikipedia.org/wiki/Exponential_smoothing#Double_exponential_smoothing)） 值。`sf`和`tf`的取值范围必须是`[0...1]`。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})。PromQL 也支持该函数。

{{< doc-see-other range_linear_regression >}}

### idelta
`idelta(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内最后 2 个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 值的差异。

{{< doc-keep-metric-name >}}

PromQL 也支持该函数。

{{< doc-see-other delta >}}

### ideriv
`ideriv(series_selector[d])`基于给定回溯窗口`d`中最后五个 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 计算秒级导数。该导数针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other deriv >}}

### increase
`increase(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内样本值的增量。

和 Prometheus 不同，它考虑了回溯窗口 d 之前的最后一个 raw sample 值。细节请阅读[这篇文档](https://www.yuque.com/icloudfly/xs51ky/qwvgrmtpg77a33a7)。

{{< doc-keep-metric-name >}}

该函数通常应用于 [counters]({{< relref "concepts.md#counter" >}}).PromQL 也支持该函数。

{{< doc-see-other increase_pure increase_prometheus delta >}}

### increase_prometheus
`increase_prometheus(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内样本值的增量。

计算方式和 Prometheus 一样，它不考虑回溯窗口 d 之前的最后一个 raw sample 值。细节请阅读[这篇文档](https://www.yuque.com/icloudfly/xs51ky/qwvgrmtpg77a33a7)。

{{< doc-keep-metric-name >}}

该函数通常应用于 [counters]({{< relref "concepts.md#counter" >}}).

{{< doc-see-other increase_pure increase >}}

### increase_pure
`increase_pure(series_selector[d])`的工作机制和 [increase](#increase) 一样，除了一种情况：它假定 [counters]({{< relref "concepts.md#counter" >}}) 总是从 0 开始计数，而 [increase](#increase) 在第一个值过大时会忽略掉它。

该函数通常应用于  [counters]({{< relref "concepts.md#counter" >}}).

{{< doc-see-other increase increase_prometheus >}}

### increases_over_time
`increases_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内出现增加的 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 值的数量。

{{< doc-keep-metric-name >}}

{{< doc-see-other decreases_over_time >}}

### integrate
`integrate(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 积分。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

### irate
`irate(series_selector[d])`使用给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内最后 2 个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 计算出每秒增量。

{{< doc-keep-metric-name >}}

该函数通常应用于 [counters]({{< relref "concepts.md#counter" >}})，PromQL 也支持该函数。

{{< doc-see-other rate rollup_rate >}}

### lag
`lag(series_selector[d])`返回给定的回溯窗口`d`内最后一个样本的时间与当前时间的间隔，以秒为单位。其针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other lifetime duration_over_time >}}

### last_over_time
`last_over_time(series_selector[d])`返回给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内最后 1 个 [raw sample]({{< relref "concepts.md#raw-samples" >}})。

PromQL 也支持该函数。

{{< doc-see-other first_over_time >}}

### lifetime
`lifetime(series_selector[d])`返回给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内第一个和最后一个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 的时间间隔，以秒为单位。

{{< doc-keep-metric-name >}}

{{< doc-see-other duration_over_time >}}

### mad_over_time
`mad_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 的 [median absolute deviation](https://en.wikipedia.org/wiki/Median_absolute_deviation)。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other mad range_mad outlier_iqr_over_time >}}

### max_over_time
`max_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的最大值。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})，PromQL 也支持该函数。

{{< doc-see-other tmax_over_time min_over_time >}}

### median_over_time
`median_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的中位数。

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other avg_over_time >}}


### min_over_time
`min_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的最小值。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})，PromQL 也支持该函数。

{{< doc-see-other tmin_over_time max_over_time >}}

### mode_over_time
`mode_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的[高频值](https://en.wikipedia.org/wiki/Mode_(statistics))。它假定 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 值都是离散的

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}}).

### outlier_iqr_over_time
`outlier_iqr_over_time(series_selector[d])`返回给定回溯窗口 d 中最后一个样本，如果它的值小于`q25-1.5*iqr`或大于`q75+1.5*iqr`，其中：

+ `iqr`回溯窗口`d`中 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 的 [Interquartile range](https://en.wikipedia.org/wiki/Interquartile_range)。
+ `q25`和`q75`回溯窗口`d`中 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 的是 25th and 75th [分位值](https://en.wikipedia.org/wiki/Percentile)。

 `outlier_iqr_over_time()`主要用于基于 gauge 指标的历史数据来检测异常。例如，`outlier_iqr_over_time(memory_usage_bytes[1h])`会在`memory_usage_bytes`指标突然超出过去一小时的平均值时触发。

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other outliers_iqr >}}

### predict_linear
`predict_linear(series_selector[d], t)`使用回溯窗口 d 中的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值，使用线性规划计算在未来 t 秒后的指标值。预测值是针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

PromQL 也支持该函数。

{{< doc-see-other range_linear_regression >}}

### present_over_time
`present_over_time(series_selector[d])`返回 1 ，如果给定的回溯窗口 d 中至少包含一个 [raw sample]({{< relref "concepts.md#raw-samples" >}})，否则就返回空。

{{< doc-keep-metric-name >}}

PromQL 也支持该函数。

### quantile_over_time
`quantile_over_time(phi, series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的`phi`分位值。其中 phi 值的取值范围必须是`[0...1]`。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}})，PromQL 也支持该函数。

{{< doc-see-other quantiles_over_time >}}

### quantiles_over_time
`quantiles_over_time("phiLabel", phi1, ..., phiN, series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的`phi*`分位值，给函数针对每一个`phi*`都返回一个独立的带有`{phiLabel="phi*"}`Label 的序列。`phi*`的取值范围必须是`[0...1]`.

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other quantile_over_time >}}

### range_over_time
`range_over_time(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的取值范围（最大值-最小值）。它等价于`max_over_time(series_selector[d]) - min_over_time(series_selector[d])`.

{{< doc-keep-metric-name >}}

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}}).

### rate
`rate(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 的平均每秒增长值。

如果中括号里的回溯窗口大小没有指定，则自动使用`max(step, scrape_interval)`，其中 step 是传递给 [/api/v1/query_range]({{< relref "concepts.md#range-query" >}}) 或 [/api/v1/query]({{< relref "concepts.md#instant-query" >}}) 的请求参数，而`scrape_interval`则是 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的间隔。这避免当 step 小于`scrape_interval`时，图表中出现了非预期的断点现象。

{{< doc-keep-metric-name >}}

PromQL 也支持该函数。

{{< doc-see-other irate rollup_rate >}}

### rate_over_sum
`rate_over_sum(series_selector[d])`计算给定回溯窗口`d`中 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 总和的每秒增量。该计算针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

该函数通常应用于 [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-keep-metric-name >}}

### resets
`resets(series_selector[d])`计算给定的 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的时间序列在给定的回溯窗口`d`内 [raw sample]({{< relref "concepts.md#raw-samples" >}})s 中出现 [counter]({{< relref "concepts.md#counter" >}}) 重置的次数。

{{< doc-keep-metric-name >}}

该函数通常应用于 [counters]({{< relref "concepts.md#counter" >}})，Counter 重置通常代表服务发生了重启。

PromQL 也支持该函数。

### rollup
`rollup(series_selector[d])`对给定的回溯窗口`d`中的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 计算最小值、最大值和平均值，并在返回的时序数据中带上`rollup="min"`, `rollup="max"`和`rollup="avg"`Label。该计算针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

支持第二个参数，是可选参数，可传入`"min"`, `"max"`或`"avg"`代表只计算一种值并且不需要追加额外的 rollup label。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other rollup_rate >}}

### rollup_candlestick
`rollup_candlestick(series_selector[d])`对给定的回溯窗口`d`中的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 使用 OHLC 计算`open`, `high`, `low`and `close`，并在返回的时序数据中带上`rollup="open"`, `rollup="high"`, `rollup="low"`and `rollup="close"`Label。该计算针对 [series_selector]({{< relref "../basic.md#filtering" >}}) 查询返回的每个时间序列单独执行计算。

支持第二个参数，是可选参数，可传入`"open"`, `"high"`或`"low"`或`"close"`代表只计算一种值并且不需要追加额外的 rollup label。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

### rollup_delta
`rollup_delta(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的差异，并返回计算出的差异的最小值、最大值和平均值，并在时间序列中附加`rollup="min"`、`rollup="max"`和`rollup="avg"`Label。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

可以传递可选的第二个参数`"min"`、`"max"`或`"avg"`来仅保留一个计算结果，并且不添加标签。

{{< doc-keep-metric-name >}}

{{< doc-see-other rollup_increase >}}

### rollup_deriv
`rollup_deriv(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的每秒导数，并返回计算出的差异的最小值、最大值和平均值，并在时间序列中附加`rollup="min"`、`rollup="max"`和`rollup="avg"`Label。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

可以传递可选的第二个参数`"min"`、`"max"`或`"avg"`来仅保留一个计算结果，并且不添加标签。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

{{< doc-keep-metric-name >}}

{{< doc-see-other rollup rollup_rate >}}

### rollup_increase
`rollup_increase(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的增加值，并返回计算出的差异的最小值、最大值和平均值，并在时间序列中附加`rollup="min"`、`rollup="max"`和`rollup="avg"`Label。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

可以传递可选的第二个参数`"min"`、`"max"`或`"avg"`来仅保留一个计算结果，并且不添加标签。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

{{< doc-keep-metric-name >}} {{< doc-see-other rollup_delta >}}

该函数通常应用于  [counters]({{< relref "concepts.md#counter" >}}).

{{< doc-see-other rollup rollup_rate >}}

### rollup_rate
`rollup_rate(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的每秒变化量，并返回计算出的差异的最小值、最大值和平均值，并在时间序列中附加`rollup="min"`、`rollup="max"`和`rollup="avg"`Label。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

可以传递可选的第二个参数`"min"`、`"max"`或`"avg"`来仅保留一个计算结果，并且不添加标签。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

{{< doc-keep-metric-name >}}

该函数通常应用于  [counters]({{< relref "concepts.md#counter" >}}).

{{< doc-see-other rollup rollup_increase >}}

### rollup_scrape_interval
`rollup_scrape_interval(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的间隔的秒数（通常是数据的采集间隔），并返回计算出的差异的最小值、最大值和平均值，并在时间序列中附加`rollup="min"`、`rollup="max"`和`rollup="avg"`Label。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

可以传递可选的第二个参数`"min"`、`"max"`或`"avg"`来仅保留一个计算结果，并且不添加标签。另请参阅 [label_match]({{< relref "./label.md#label_match" >}})

{{< doc-keep-metric-name >}} {{< doc-see-other scrape_interval >}}

### scrape_interval
`scrape_interval(series_selector[d]) `计算给定回溯窗口`d`上相邻 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 之间的间隔的平均秒数（通常是数据的采集间隔）并返回。计算是针对从给定 [series_selector]({{< relref "concepts.md#filtering" >}}) 返回的每个时间序列单独进行的。 

{{< doc-keep-metric-name >}}

{{< doc-see-other rollup_scrape_interval >}}

### share_gt_over_time
`share_gt_over_time(series_selector[d], gt)`返回给定回溯窗口`d`上大于`gt`的原始样本的比例（范围在`[0...1]`之间）。该比例是针对从给定`series_selector`返回的每个时间序列独立计算的。

此函数对于计算 SLI 和 SLO 非常有用。例如：`share_gt_over_time(up[24h], 0)`- 返回过去 24 小时的服务可用性。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other share_le_over_time count_gt_over_time >}}

### share_le_over_time
`share_le_over_time(series_selector[d], le)`返回给定回溯窗口`d`上小于`le`的原始样本的比例（范围在`[0...1]`之间）。该比例是针对从给定`series_selector`返回的每个时间序列独立计算的。

此函数对于计算 SLI 和 SLO 非常有用。例如：`share_le_over_time(memory_usage_bytes[24h], 100*1024*1024)`- 返回过去 24 小时的内存使用率小于等于`100MB`的时间占比。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other share_gt_over_time count_le_over_time >}}

### share_eq_over_time
`share_eq_over_time(series_selector[d], eq)`返回给定回溯窗口`d`上等于`eq`的原始样本的比例（范围在`[0...1]`之间）。该比例是针对从给定`series_selector`返回的每个时间序列独立计算的。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other count_eq_over_time >}}

### stddev_over_time
`stddev_over_time(series_selector[d])`对`series_selector`返回的每个时间序列计算给定回溯窗口`d`上原始样本的标准差。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

PromQL 也支持该函数。

{{< doc-see-other stdvar_over_time >}}

### stdvar_over_time
`stdvar_over_time(series_selector[d])`针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 的方差并返回。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

PromQL 也支持该函数。

{{< doc-see-other stddev_over_time >}}

### sum_eq_over_time
`sum_eq_over_time(series_selector[d], eq)`针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上等于`eq`的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值的总和并返回。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other sum_over_time count_eq_over_time >}}


### sum_gt_over_time
`sum_gt_over_time(series_selector[d], gt)`针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上大于`gt`的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值的总和并返回。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other sum_over_time count_gt_over_time >}}

### sum_le_over_time
`sum_le_over_time(series_selector[d], le)`针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上小于或等于`le`的 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值的总和并返回。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other sum_over_time count_le_over_time >}}

### sum_over_time
`sum_over_time(series_selector[d])`是一个汇总函数，它针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值的总和并返回。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

PromQL 也支持该函数。

### sum2_over_time
`sum2_over_time(series_selector[d])`针对`series_selector`返回的每条时间序列独立计算，算出给定回溯窗口`d`上 [raw samples]({{< relref "concepts.md#raw-samples" >}}) 值的平方和并返回。 

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

### timestamp
`timestamp(series_selector[d])`针对`series_selector`返回的每条时间序列独立计算，返回给定回溯窗口`d`上最后一个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 的时间戳（以秒为单位，精确到毫秒）。

{{< doc-keep-metric-name >}}

PromQL 也支持该函数。

{{< doc-see-other time now >}}

### timestamp_with_name
`timestamp_with_name(series_selector[d])`针对`series_selector`返回的每条时间序列独立计算，返回给定回溯窗口`d`上最后一个 [raw sample]({{< relref "concepts.md#raw-samples" >}}) 的时间戳（以秒为单位，精确到毫秒）。

和 timestamp 函数区别是在汇总结果中保留了 Metric  名称。

另请参阅 [timestamp](#timestamp) 和 [keep_metric_names]({{< relref "../basic.md#keep_metric_names" >}}) 修改器.

### tfirst_over_time
`tfirst_over_time(series_selector[d])`针对`series_selector`返回的每条时间序列独立计算，返回给定回溯窗口`d`上第一个 raw sample 的时间戳（以秒为单位，精确到毫秒）。

{{< doc-keep-metric-name >}}

{{< doc-see-other first_over_time >}}

### tlast_change_over_time
`tlast_change_over_time (series_selector [d])`针对`series_selector`返回的每条时间序列独立计算，返回给定回溯窗口`d`上最后一次变化的时间戳（以秒为单位，精确到毫秒）。

{{< doc-keep-metric-name >}}

{{< doc-see-other last_over_time >}}

### tlast_over_time
`tlast_over_time`是 [timestamp](#timestamp) 函数的别名。

{{< doc-see-other tlast_change_over_time >}}

### tmax_over_time
`tmax_over_time(series_selector[d])`返回给定回溯窗口`d`上具有最大值的 raw sample 的时间戳（以秒为单位，精确到毫秒）。它针对`series_selector`返回的每条时间序列独立计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other max_over_time >}}

### tmin_over_time
`tmin_over_time(series_selector[d])`返回给定回溯窗口`d`上具有最小值的 raw sample 的时间戳（以秒为单位，精确到毫秒）。它针对`series_selector`返回的每条时间序列独立计算。

{{< doc-keep-metric-name >}}

{{< doc-see-other min_over_time >}}

### zscore_over_time
`zscore_over_time(series_selector[d])`is a [rollup function](#rollup-functions), which returns [z-score](https://en.wikipedia.org/wiki/Standard_score) for [raw samples]({{< relref "concepts.md#raw-samples" >}}) on the given lookbehind window `d`. It is calculated independently per each time series returned from the given [series_selector]({{< relref "concepts.md#filtering" >}}).

`zscore_over_time(series_selector[d])`返回给定回溯窗口`d`上 raw samples 的 [z-score](https://en.wikipedia.org/wiki/Standard_score)。它针对`series_selector`返回的每条时间序列独立计算。

{{< doc-keep-metric-name >}}

该函数通常应用于  [gauges]({{< relref "concepts.md#gauge" >}}).

{{< doc-see-other zscore range_trim_zscore outlier_iqr_over_time >}}