---
title: 数值转换
date: 2024-10-28T20:08:09+08:00
description: MetricsQL 支持的数值转换函数列表及介绍，比如 abs, ceil 等等
keywords:
- 转换函数
- 时区
- 时间函数
- 无数据
- 智能预测
weight: 4
---

**Transform 函数** 对 [rollup 结果]({{< relref "./rollup.md" >}}) 做数值转换。例如，`abs(delta(temperature[24h]))` 计算从`delta(temperature[24h])` 返回的每条 timeseries 的每个数据点的绝对值。

## 一些细节

- 如果 transform 函数直接应用于 [series selector]({{< relref "../../../concepts.md#filtering" >}})，则在计算转换之前会自动应用 [default_rollup()]({{< relref "./rollup.md#default_rollup" >}}) 函数。例如，`abs(temperature)`会被[隐式转换]({{< relref "../_index.md#conversion" >}})为 `abs(default_rollup(temperature))`。
- 所有 transform 函数都可使用 `keep_metric_names` 修饰符。如果使用了，则函数不会从结果时间序列中删除 Metric 名称。请参阅[这些文档]({{< relref "../_index.md#keep_metric_name" >}})。

另请参阅[隐式查询转换]({{< relref "../_index.md#conversion" >}})。

## 函数列表

### 内置数学函数

内置数学函数是可以独立于查询`q`直接使用，自动返回期望数值，比如随机数。

#### pi
`pi()` 返回[圆周率π](https://en.wikipedia.org/wiki/Pi).

这个函数 PromQL 中也支持。

#### now
`now()` 返回当前的时间戳，返回浮点数，单位秒。

#### rand
`rand(seed)`返回`[0...1]`范围的随机数。 可选参数`seed`代表随机种子。

{{< doc-see-other rand_normal rand_exponential >}}

#### rand_exponential

返回具有[指数分布](https://en.wikipedia.org/wiki/Exponential_distribution)的伪随机数。可选参数`seed`可以用作伪随机数生成器的种子。

{{< doc-see-other rand rand_normal >}}

#### rand_normal
`rand_normal(seed)`返回具有[正态分布](https://en.wikipedia.org/wiki/Normal_distribution)的伪随机数。可选参数`seed`可以用作伪随机数生成器的种子。

{{< doc-see-other rand rand_exponential >}}


### 单一数值转换

#### abs
`abs(q)`对`q`返回的每一个数值取绝对值。

这个函数 PromQL 中也支持。

#### ceil
`ceil(q)`对`q`返回的每一个数值**向上取整**。

这个函数 PromQL 中也支持。

{{< doc-see-other floor round >}}

#### floor
`floor(q)`对`q`返回的每一个数值**向下取整**。

这个函数 PromQL 中也支持。

{{< doc-see-other ceil round >}}

#### round
`round(q, nearest)`对`q`返回的每一个数值进行四舍五入。如果设置了`nearest`，则四舍五入到`nearest`的倍数。

这个函数 PromQL 中也支持。

{{< doc-see-other floor ceil >}}


#### clamp
`clamp(q, min, max)` 使用给定的 `min` 和 `max` 值对 `q` 返回的每条 timeseries 的每个数值进行限制。小于`min`的换成`min`，大于`max`的值换成`max`。

这个函数 PromQL 中也支持。

{{< doc-see-other clamp_min clamp_max >}}


#### clamp_max
`clamp_max(q, max)` 使用给定的`max`值对`q`返回的每条 timeseries 的每个数值进行限制。大于`max`的值换成`max`。

这个函数 PromQL 中也支持。

{{< doc-see-other clamp clamp_min >}}

#### clamp_min
`clamp_min(q, min)` 使用给定的`minx`值对`q`返回的每条 timeseries 的每个数值进行限制。小于`min`的换成`min`。

这个函数 PromQL 中也支持。

{{< doc-see-other clamp clamp_max >}}

#### deg
`deg(q)`对`q`返回的每一个数值进行[弧度转换](https://en.wikipedia.org/wiki/Radian#Conversions)。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other rad >}}

#### rad
`rad(q)`对`q`返回的每一个数值进行[角度转换](https://en.wikipedia.org/wiki/Radian#Conversions)。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other deg >}}

#### exp
`exp(q)`对`q`返回的每一个数值`v`计算`e^v`。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other ln >}}

#### sqrt
`sqrt(q)`对`q`返回的每一个数值计算平方根。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### sgn
`sgn(q)`对`q`返回每个数据点`v`进行正负数判断。 
- 如果`v>0`，返回`1`。
- 如果`v<0`，返回`-1`。
- 如果`v==0`，返回`0`。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。


### 位运算

#### bitmap_and
`bitmap_and(q, mask)` 使用从 `q` 返回的每条 timeseries 中每个点`v`计算按位**与**`v & mask`。

{{< doc-keep-metric-name >}}

#### bitmap_or
`bitmap_or(q, mask)` 使用从 `q` 返回的每条 timeseries 中每个点`v`计算按位**或**`v | mask`。

{{< doc-keep-metric-name >}}

#### bitmap_xor
`bitmap_xor(q, mask)` 使用从 `q` 返回的每条 timeseries 中每个点`v`计算按位**异或**`v ^ mask`。

{{< doc-keep-metric-name >}}


### Histogram(直方图) {#histogram}

#### histogram_avg
`histogram_avg(buckets)` 计算给定 `buckets` 的平均值。它可以用于计算跨多个 timeseries 的给定时间范围内的平均值。例如，`histogram_avg(sum(histogram_over_time(response_time_duration_seconds[5m])) by (vmrange,job))` 将返回过去 5 分钟内每个 `job` 的平均响应时间。

#### histogram_quantile
`histogram_quantile(phi, buckets)` 计算给定 [直方图桶](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) 上的 `phi`-[百分位数](https://en.wikipedia.org/wiki/Percentile)。`phi` 必须在 `[0...1]` 范围内。例如，`histogram_quantile(0.5, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))` 将返回过去 5 分钟内所有请求的中位请求持续时间。

该函数接受可选的第三个参数 - `boundsLabel`。在这种情况下，它返回具有给定 `boundsLabel` Label 的估计百分位数的 `lower` 和 `upper` 界限。详情请参见 [此问题](https://github.com/prometheus/prometheus/issues/5706)。

当在多个直方图上计算 [百分位数](https://en.wikipedia.org/wiki/Percentile) 时，所有输入直方图 **必须** 具有相同边界的桶，例如，它们必须具有相同的 `le` 或 `vmrange` Label 结合。否则，返回的结果可能无效。详情请参见 [此问题](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/3231)。

此函数由 PromQL 支持（不包括 `boundLabel` 参数）。

{{< doc-see-other histogram_quantiles histogram_share quantile >}}

#### histogram_quantiles
`histogram_quantiles("phiLabel", phi1, ..., phiN, buckets)`计算给定 [直方图桶](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350)上的`phi*`分位数。参数`phi*`必须在`[0...1]`范围内。例如，`histogram_quantiles('le', 0.3, 0.5, sum(rate(http_request_duration_seconds_bucket[5m]) by (le))`。每个计算出的分位数在一个单独的时间序列中返回，并带有相应的 `{phiLabel="phi*"}` Label。

{{< doc-see-other histogram_quantile >}}

#### buckets_limit
`buckets_limit(limit, buckets)` 将 [直方图桶](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350)的数量限制为给定的`limit`。

{{< doc-see-other prometheus_buckets histogram_quantile >}}

#### histogram_share
`histogram_share(le, buckets)` 计算落在 `le` 以下的 `buckets` 的份额（范围 `[0...1]`）。此函数对于计算 SLI 和 SLO 很有用。这与 [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile) 是相反的。

该函数接受可选的第三个参数 - `boundsLabel`。在这种情况下，它返回具有给定 `boundsLabel` Label 的估计份额的 `lower` 和 `upper` 界限。

#### histogram_stddev
`histogram_stddev(buckets)` 计算给定 `buckets` 的标准偏差。

#### histogram_stdvar
`histogram_stdvar(buckets)` 计算给定 `buckets` 的标准方差。它可以用于计算跨多个时间序列的给定时间范围内的标准偏差。例如，`histogram_stdvar(sum(histogram_over_time(temperature[24])) by (vmrange,country))` 将返回每个国家在过去 24 小时内的温度标准偏差。

#### prometheus_buckets
`prometheus_buckets(buckets)` 将带有 `vmrange` 标签的 [VictoriaMetrics 直方图桶](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) 转换为带有 `le` 标签的 Prometheus 直方图桶。这对于在 Grafana 中构建热图可能很有用。

{{< doc-see-other histogram_quantile buckets_limit >}}


### 滑动函数

`running_`开头的为s滑动函数，比如`running_avg`对于序列中的第`i`个数值，计算第`[1...i]`共`i`个数据点的均值。
比如：
| value | running_avg |
| --- | --- |
| 10 | 10(10/1) |
| 20 | 15(30/2) |
| 30 | 20(60/3) |
| 40 | 25(100/4) |
| 50 | 30(150/5) |

#### running_avg
`running_avg(q)` 计算由 `q` 返回的每条时间序列的运行平均值。

#### running_max
`running_avg(q)` 计算由 `q` 返回的每条时间序列的运行最大值。

#### running_min
`running_avg(q)` 计算由 `q` 返回的每条时间序列的运行最小值。

#### running_sum
`running_avg(q)` 计算由 `q` 返回的每条时间序列的运行加和。

### 排序

#### sort
`sort(q)`使用`q`返回的每个 timeseries 里最后一个数据点，对 timeseries 进行升序排序。


这个函数 PromQL 中也支持。

{{< doc-see-other sort_desc sort_by_label >}}

#### sort_desc
`sort(q)`使用`q`返回的每个 timeseries 里最后一个数据点，对 timeseries 进行降序排序。

这个函数 PromQL 中也支持。

{{< doc-see-other sort sort_by_label >}}

### 对数函数

#### ln
`ln(q)`对`q`返回的每一个数据点都计算`ln(v)`并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other exp log2 >}}

#### log2
`log2(q)`对`q`返回的每一个数据点都计算`log2(v)`并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other log10 ln >}}

#### log10
`log10(q)`对`q`返回的每一个数据点都计算`log10(v)`并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other log2 ln >}}


### 三角函数

#### sin
`sin(q)`对`q`返回的每一个数据点都计算`sin(v)`并返回。

{{< doc-keep-metric-name >}}

{{< doc-see-other cos >}}

#### sinh
`sinh(q)`对`q`返回的每一个数据点都计算[hyperbolic sine](https://en.wikipedia.org/wiki/Hyperbolic_functions)并返回。

{{< doc-keep-metric-name >}}

{{< doc-see-other cosh >}}

#### cos
`cos(q)`对`q`返回的每一个数据点都计算`cos(v)`并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other sin >}}

#### cosh
`cosh(q)`对`q`返回的每一个数据点都计算[hyperbolic cosine](https://en.wikipedia.org/wiki/Hyperbolic_functions)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other acosh >}}


#### tan
`tan(q)`对`q`返回的每一个数据点都计算`tan(v)`并返回。

{{< doc-keep-metric-name >}}

This function is supported by MetricsQL.

{{< doc-see-other atan >}}

#### tanh
`tanh(q)`对`q`返回的每一个数据点都计算[hyperbolic tangent](https://en.wikipedia.org/wiki/Hyperbolic_functions)并返回。

{{< doc-keep-metric-name >}}

This function is supported by MetricsQL.

{{< doc-see-other atanh >}}

#### acos
`acos(q)`对`q`返回的每一个数据点都计算[inverse cosine](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other asin cos >}}

#### acosh
`acosh(q)`对`q`返回的每一个数据点都计算[inverse hyperbolic cosine](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_cosine)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other sinh >}}

#### asin
`asin(q)`对`q`返回的每一个数据点都计算[inverse sine](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other acos sin >}}

#### asinh
`asinh(q)`对`q`返回的每一个数据点都计算[inverse hyperbolic sine](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_sine)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other sinh >}}

#### atan
`atan(q)`对`q`返回的每一个数据点都计算[inverse tangent](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other tan >}}

#### atanh
`atanh(q)`对`q`返回的每一个数据点都计算[inverse hyperbolic tangent](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_tangent)并返回。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other tanh >}}

### 时间函数

#### start
`start()`返回第一个数据点的 unix 时间戳，单位是**秒**。

它通常是指 [/api/v1/query_range]({{< relref "../../_index.md#range-query" >}})接口中的`start`查询参数。

{{< doc-see-other end time now >}}

#### end
`end()`返回最后一个数据点的 unix 时间戳，单位是**秒**。

它通常是指 [/api/v1/query_range]({{< relref "../../_index.md#range-query" >}})接口中的`end`查询参数。

{{< doc-see-other start time now >}}

#### step
`step()`返回数据点之间的时间间隔，单位是**秒**。
它通常是指 [/api/v1/query_range]({{< relref "../../_index.md#range-query" >}})接口中的`step`查询参数。

{{< doc-see-other start end >}}

#### time
`time()` 返回 unix 时间戳，单位**秒**。

这个函数 PromQL 中也支持。

{{< doc-see-other timestamp start now end >}}

#### day_of_month
`day_of_month(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间是月份中的第几天。其返回的值在 `[1...31]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other day_of_week day_of_year >}}

#### day_of_week
`day_of_week(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间是一周中的第几天。其返回的值在 `[1...7]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other day_of_month day_of_year >}}

#### day_of_year
`day_of_year(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间是一年中的第几天。其返回的值在 `[1...365]` 范围内，如果是闰年，取值范围就是`[1...366]`。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

{{< doc-see-other day_of_week day_of_month >}}

#### days_in_month
`days_of_month(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间所属月总共有多少天。其返回的值在 `[28...31]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### minute
`minute(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间的分钟位。其返回的值在 `[0...59]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### hour
`hour(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间的小时位。其返回的值在 `[0...23]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### month
`hour(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间是一年中的第几月。其返回的值在 `[1...12]` 范围内。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### year
`hour(q)`期望`q`返回数据是 Unix 时间戳，然后计算每个数值代表的时间的年份。

{{< doc-keep-metric-name >}}

这个函数 PromQL 中也支持。

#### now
`now()` 返回当前的时间戳，返回浮点数，单位秒。

#### timezone_offset
`timezone_offset(tz)`返回给定时区`tz`相对于 UTC 的秒数偏移量。这在与日期时间相关的函数结合使用时非常有用。例如，`day_of_week(time()+timezone_offset("America/Los_Angeles"))`将返回`America/Los_Angeles`时区的星期几。

特殊的`Local`时区可以用于返回 VictoriaMetrics 运行所在主机设置的时区偏移量。

请阅读[时区列表](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)。


### 向量计算函数

向量计算函数应用于一个数组，即对每个 timeseries 的随时间变化的数据点，进行线性计算，比如方差，线性回归，z-score等。

#### range_avg
`range_avg(q)` 计算 `q` 返回的每个 timeseries 中各点的平均值。

#### range_first
`range_first(q)` 计算 `q` 返回的每个 timeseries 中各点的第一个值。

#### range_last
`range_last(q)` 计算 `q` 返回的每个 timeseries 中各点的最后一个值。

#### range_sum
`range_sum(q)` 计算 `q` 返回的每条 timeseries 中各点的总和。

#### range_linear_regression
`range_linear_regression(q)` 针对 `q` 返回的每条 timeseries，在选定的时间范围内计算[简单线性回归](https://en.wikipedia.org/wiki/Simple_linear_regression)。此函数对于容量规划和预测非常有用。

#### range_mad
`range_mad(q)` 计算 `q` 返回的每条 timeseries 中各点的[中位数绝对偏差](https://en.wikipedia.org/wiki/Median_absolute_deviation)。

{{< doc-see-other mad mad_over_time >}}

#### range_max
`range_max(q)` 计算 `q` 返回的每条时间序列中各点的最大值。

#### range_median
`range_median(q)` 计算 `q` 返回的每条时间序列中各点的中位数。

#### range_min
`range_min(q)` 计算 `q` 返回的每条时间序列中各点的最小值。

#### range_normalize
`range_normalize(q1, ...)`将`q1, ...` 返回的 timeseries 的值归一化到 `[0 ... 1]` 范围内。此函数对于关联具有不同值范围的 timeseries 非常有用。

{{< doc-see-other share >}}

#### range_quantile
`range_quantile(phi, q)` 返回`q`返回的每条 timeseries 中各点的`phi`分位数。`phi`的取值范围必须是`[0...1]`。

#### range_stddev
`range_stddev(q)` 计算选定时间范围内`q`返回的每条 tiemseries 的[标准差](https://en.wikipedia.org/wiki/Standard_deviation)。

#### range_stdvar
`range_stdvar(q)` 计算选定时间范围内`q`返回的每条 timeseries 的[方差](https://en.wikipedia.org/wiki/Variance)。

#### range_trim_outliers
`range_trim_outliers(k, q)` 删除距离 `range_median(q)` 超过 `k*range_mad(q)` 的点。例如，它等价于以下查询：`q ifnot (abs(q - range_median(q)) > k*range_mad(q))`。

{{< doc-see-other range_trim_spikes range_trim_zscore >}}

#### range_trim_spikes
`range_trim_spikes(phi, q)` 删除 `q` 返回的时间序列中最大的 `phi`% 的尖峰。`phi` 必须在 `[0..1]` 范围内，其中 `0` 表示 `0%`，`1` 表示 `100%`。

{{< doc-see-other range_trim_outliers range_trim_zscore >}}

#### range_trim_zscore
`range_trim_zscore(z, q)` 删除距离 `range_avg(q)` 超过 `z*range_stddev(q)` 的点。例如，它等价于以下查询：`q ifnot (abs(q - range_avg(q)) > z*range_avg(q))`。

{{< doc-see-other range_trim_outliers range_trim_spikes >}}

#### range_zscore
`range_zscore(q)` 计算 `q` 返回的各点的[z-score](https://en.wikipedia.org/wiki/Standard_score)，例如，它等价于以下查询：`(q - range_avg(q)) / range_stddev(q)`。


### 智能预测

#### smooth_exponential
`smooth_exponential(q, sf)` 使用给定的平滑因子`sf`对`q`返回的每条时间序列的点进行平滑处理，采用[指数移动平均](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average)。

{{< doc-see-other range_linear_regression >}}

#### ru
`ru(free, max)` 计算给定的 `free` 和 `max` 资源在 `[0%...100%]` 范围内的资源利用率。例如，`ru(node_memory_MemFree_bytes, node_memory_MemTotal_bytes)` 返回基于 [node_exporter](https://github.com/prometheus/node_exporter) 指标的内存利用率。

#### ttf
`ttf(free)` 估算耗尽 `free` 资源所需的时间（以秒为单位）。例如，`ttf(node_filesystem_avail_byte)` 返回存储空间耗尽所需的时间。此函数在容量规划中可能非常有用。

该函数是根据历史数据点的增长速率，来估算出增长到`100%`需要多久。


### 无数据判断转换

#### scalar

如果`q`值包含一个时间序列，`scalar(q)`则直接返回；否则返回空结果。

这个函数 PromQL 中也支持。

#### absent

如果`q`没有返回数据，则`absent(q)`返回`1`。否则它返回空结果。

这个函数 PromQL 中也支持。

另请参阅 [absent_over_time]({{< relref "./rollup.md#absent_over_time" >}})

#### union
`union(q1, ..., qN)`返回`q1,…,qN`返回的 timeseries 的并集。`union`函数名可以省略，所以`union(q1, q2)`和`(q1, q2)`是等价的。

期望每个`q*`查询返回的 timeseries 中的 Label 都是存在一定差异的。否则就只返回其中一条。可使用 [alias]({{< relref "./label.md#alias" >}}) 和 [label_set]({{< relref "./label.md#label_set" >}}) 函数为每个`q*`查询提供独一无二的 Label以避免出现重复：

#### drop_empty_series
`drop_empty_series(q)`删掉`q`返回的没有数值的 timeseries。

此函数的一大用途是：只对非空序列使用`default`操作。例如，`drop_empty_series(temperature < 30) default 42`返回在选定时间范围内至少有一个 raw sample 小于30的序列，如果没有，就用`42`来补充序列中的空缺。

否则，`(temperature < 30) default 40`返回所有的`temperature`序列，即使它们没有样本小于`30`，函数也会使用`40`作为替代值。

#### vector
`vector(q)` 返回 `q`，它在 MetricsQL 里什么都不做。

这个函数 PromQL 中也支持。


#### interpolate
如果`q`返回的数值中存在空缺，`interpolate(q)`则使用空缺前后最接近的 2 个非空数据点进行线性计算，将线性结果值补充到空缺中。

{{< doc-see-other keep_last_value keep_next_value >}}

#### keep_last_value
如果`q`返回的数值中存在空缺，`keep_last_value(q)`则将**空缺前**最接近的非空数据点，补充到空缺中。

{{< doc-see-other keep_next_value interpolate >}}

#### keep_next_value
如果`q`返回的数值中存在空缺，`keep_last_value(q)`则将**空缺后**最接近的非空数据点，补充到空缺中。

{{< doc-see-other keep_last_value interpolate >}}


#### remove_resets
`remove_resets(q)`纠正`q`返回的时间序列中 Counter 重置数据点。

比如 Counter 类指标在递增过程中出现了归零，则`remove_resets`会将归零后的数据点都加上归零前的最后数据点，以保证结果中的数值是绝对递增的。

### 其他

#### limit_offset
`limit_offset(limit, offset, q)` skips `offset`time series from series returned by `q`and then returns up to `limit`of the remaining time series per each group.

`limit_offset(limit, offset, q)`对`q`返回的诸多 timeseries，跳过`offset`个 timeseries，然后返回后面的最多`limit`个 timeseries 数据。

该函数主要用于对`q`返回的 timeseries 进行简单的分页。 

{{< callout type="info" >}}
分页并不会优化重查询，因为系统还是会对`q`做完整的计算，在计算结果中挑选`limit`条结果返回。主要的用途是缓解 Grafana 绘图压力，避免浏览器崩溃。
{{< /callout >}}


另请参阅 [limitk]({{< relref "./aggregation.md#limitk" >}})