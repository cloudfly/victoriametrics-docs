---
title: 聚合统计
weight: 3
---

**Aggregate functions** calculate aggregates over groups of [rollup results](https://docs.victoriametrics.com/metricsql/#rollup-functions).

Additional details:

+ By default, a single group is used for aggregation. Multiple independent groups can be set up by specifying grouping labels in `by` and `without` modifiers. For example, `count(up) by (job)` would group [rollup results](https://docs.victoriametrics.com/metricsql/#rollup-functions) by `job` label value and calculate the [count](https://docs.victoriametrics.com/metricsql/#count) aggregate function independently per each group, while `count(up) without (instance)` would group [rollup results](https://docs.victoriametrics.com/metricsql/#rollup-functions) by all the labels except `instance` before calculating [count](https://docs.victoriametrics.com/metricsql/#count) aggregate function independently per each group. Multiple labels can be put in `by` and `without` modifiers.
+ If the aggregate function is applied directly to a [series_selector](https://docs.victoriametrics.com/keyconcepts/#filtering), then the [default_rollup()](https://docs.victoriametrics.com/metricsql/#default_rollup) function is automatically applied before calculating the aggregate. For example, `count(up)` is implicitly transformed to `count(default_rollup(up))`.
+ Aggregate functions accept arbitrary number of args. For example, `avg(q1, q2, q3)` would return the average values for every point across time series returned by `q1`, `q2` and `q3`.
+ Aggregate functions support optional `limit N` suffix, which can be used for limiting the number of output groups. For example, `sum(x) by (y) limit 3` limits the number of groups for the aggregation to 3. All the other groups are ignored.

See also [implicit query conversions](https://docs.victoriametrics.com/metricsql/#implicit-query-conversions).

The list of supported aggregate functions:

#### any [#](https://docs.victoriametrics.com/metricsql/#any)
`any(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns a single series per `group_labels` out of time series returned by `q`.

See also [group](https://docs.victoriametrics.com/metricsql/#group).

#### avg [#](https://docs.victoriametrics.com/metricsql/#avg)
`avg(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the average value per `group_labels` for time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### bottomk [#](https://docs.victoriametrics.com/metricsql/#bottomk)
`bottomk(k, q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` points with the smallest values across all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

See also [topk](https://docs.victoriametrics.com/metricsql/#topk), [bottomk_min](https://docs.victoriametrics.com/metricsql/#bottomk_min) and [#bottomk_last](https://docs.victoriametrics.com/metricsql/#bottomk_last).

#### bottomk_avg [#](https://docs.victoriametrics.com/metricsql/#bottomk_avg)
`bottomk_avg(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the smallest averages. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `bottomk_avg(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the smallest averages plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [topk_avg](https://docs.victoriametrics.com/metricsql/#topk_avg).

#### bottomk_last [#](https://docs.victoriametrics.com/metricsql/#bottomk_last)
`bottomk_last(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the smallest last values. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `bottomk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the smallest maximums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [topk_last](https://docs.victoriametrics.com/metricsql/#topk_last).

#### bottomk_max [#](https://docs.victoriametrics.com/metricsql/#bottomk_max)
`bottomk_max(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the smallest maximums. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `bottomk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the smallest maximums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [topk_max](https://docs.victoriametrics.com/metricsql/#topk_max).

#### bottomk_median [#](https://docs.victoriametrics.com/metricsql/#bottomk_median)
`bottomk_median(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the smallest medians. If an optional`other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `bottomk_median(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the smallest medians plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [topk_median](https://docs.victoriametrics.com/metricsql/#topk_median).

#### bottomk_min [#](https://docs.victoriametrics.com/metricsql/#bottomk_min)
`bottomk_min(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the smallest minimums. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `bottomk_min(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the smallest minimums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [topk_min](https://docs.victoriametrics.com/metricsql/#topk_min).

#### count [#](https://docs.victoriametrics.com/metricsql/#count)
`count(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the number of non-empty points per `group_labels` for time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### count_values [#](https://docs.victoriametrics.com/metricsql/#count_values)
`count_values("label", q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which counts the number of points with the same value and stores the counts in a time series with an additional `label`, which contains each initial value. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

See also [count_values_over_time](https://docs.victoriametrics.com/metricsql/#count_values_over_time) and [label_match](https://docs.victoriametrics.com/metricsql/#label_match).

#### distinct [#](https://docs.victoriametrics.com/metricsql/#distinct)
`distinct(q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates the number of unique values per each group of points with the same timestamp.

See also [distinct_over_time](https://docs.victoriametrics.com/metricsql/#distinct_over_time).

#### geomean [#](https://docs.victoriametrics.com/metricsql/#geomean)
`geomean(q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates geometric mean per each group of points with the same timestamp.

#### group [#](https://docs.victoriametrics.com/metricsql/#group)
`group(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns `1` per each `group_labels` for time series returned by `q`.

This function is supported by PromQL. See also [any](https://docs.victoriametrics.com/metricsql/#any).

#### histogram [#](https://docs.victoriametrics.com/metricsql/#histogram)
`histogram(q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates [VictoriaMetrics histogram](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) per each group of points with the same timestamp. Useful for visualizing big number of time series via a heatmap. See [this article](https://medium.com/@valyala/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) for more details.

See also [histogram_over_time](https://docs.victoriametrics.com/metricsql/#histogram_over_time) and [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile).

#### limitk [#](https://docs.victoriametrics.com/metricsql/#limitk)
`limitk(k, q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series per each `group_labels` out of time series returned by `q`. The returned set of time series remain the same across calls.

See also [limit_offset](https://docs.victoriametrics.com/metricsql/#limit_offset).

#### mad [#](https://docs.victoriametrics.com/metricsql/#mad)
`mad(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the [Median absolute deviation](https://en.wikipedia.org/wiki/Median_absolute_deviation) per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

See also [range_mad](https://docs.victoriametrics.com/metricsql/#range_mad), [mad_over_time](https://docs.victoriametrics.com/metricsql/#mad_over_time), [outliers_mad](https://docs.victoriametrics.com/metricsql/#outliers_mad) and [stddev](https://docs.victoriametrics.com/metricsql/#stddev).

#### max [#](https://docs.victoriametrics.com/metricsql/#max)
`max(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the maximum value per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### median [#](https://docs.victoriametrics.com/metricsql/#median)
`median(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the median value per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

#### min [#](https://docs.victoriametrics.com/metricsql/#min)
`min(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the minimum value per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### mode [#](https://docs.victoriametrics.com/metricsql/#mode)
`mode(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns [mode](https://en.wikipedia.org/wiki/Mode_(statistics)) per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

#### outliers_iqr [#](https://docs.victoriametrics.com/metricsql/#outliers_iqr)
`outliers_iqr(q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns time series from `q` with at least a single point outside e.g. [Interquartile range outlier bounds](https://en.wikipedia.org/wiki/Interquartile_range) `[q25-1.5*iqr .. q75+1.5*iqr]` comparing to other time series at the given point, where:

+ `iqr` is an [Interquartile range](https://en.wikipedia.org/wiki/Interquartile_range) calculated independently per each point on the graph across `q` series.
+ `q25` and `q75` are 25th and 75th [percentiles](https://en.wikipedia.org/wiki/Percentile) calculated independently per each point on the graph across `q` series.

The `outliers_iqr()` is useful for detecting anomalous series in the group of series. For example, `outliers_iqr(temperature) by (country)` returns per-country series with anomalous outlier values comparing to the rest of per-country series.

See also [outliers_mad](https://docs.victoriametrics.com/metricsql/#outliers_mad), [outliersk](https://docs.victoriametrics.com/metricsql/#outliersk) and [outlier_iqr_over_time](https://docs.victoriametrics.com/metricsql/#outlier_iqr_over_time).

#### outliers_mad [#](https://docs.victoriametrics.com/metricsql/#outliers_mad)
`outliers_mad(tolerance, q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns time series from `q` with at least a single point outside [Median absolute deviation](https://en.wikipedia.org/wiki/Median_absolute_deviation) (aka MAD) multiplied by `tolerance`. E.g. it returns time series with at least a single point below `median(q) - mad(q)` or a single point above `median(q) + mad(q)`.

See also [outliers_iqr](https://docs.victoriametrics.com/metricsql/#outliers_iqr), [outliersk](https://docs.victoriametrics.com/metricsql/#outliersk) and [mad](https://docs.victoriametrics.com/metricsql/#mad).

#### outliersk [#](https://docs.victoriametrics.com/metricsql/#outliersk)
`outliersk(k, q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series with the biggest standard deviation (aka outliers) out of time series returned by `q`.

See also [outliers_iqr](https://docs.victoriametrics.com/metricsql/#outliers_iqr) and [outliers_mad](https://docs.victoriametrics.com/metricsql/#outliers_mad).

#### quantile [#](https://docs.victoriametrics.com/metricsql/#quantile)
`quantile(phi, q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates `phi`-quantile per each `group_labels` for all the time series returned by `q`. `phi` must be in the range `[0...1]`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

See also [quantiles](https://docs.victoriametrics.com/metricsql/#quantiles) and [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile).

#### quantiles [#](https://docs.victoriametrics.com/metricsql/#quantiles)
`quantiles("phiLabel", phi1, ..., phiN, q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates `phi*`-quantiles for all the time series returned by `q` and return them in time series with `{phiLabel="phi*"}` label. `phi*` must be in the range `[0...1]`. The aggregate is calculated individually per each group of points with the same timestamp.

See also [quantile](https://docs.victoriametrics.com/metricsql/#quantile).

#### share [#](https://docs.victoriametrics.com/metricsql/#share)
`share(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns shares in the range `[0..1]` for every non-negative points returned by `q` per each timestamp, so the sum of shares per each `group_labels` equals 1.

This function is useful for normalizing [histogram bucket](https://docs.victoriametrics.com/keyconcepts/#histogram) shares into `[0..1]` range:

```plain
share(
  sum(
    rate(http_request_duration_seconds_bucket[5m])
  ) by (le, vmrange)
)
```

<font style="color:rgb(187, 187, 187);">MetricsQL</font>

<font style="color:rgb(255, 255, 255);background-color:rgb(233, 70, 0);">Copy</font>

See also [range_normalize](https://docs.victoriametrics.com/metricsql/#range_normalize).

#### stddev [#](https://docs.victoriametrics.com/metricsql/#stddev)
`stddev(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates standard deviation per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### stdvar [#](https://docs.victoriametrics.com/metricsql/#stdvar)
`stdvar(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates standard variance per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### sum [#](https://docs.victoriametrics.com/metricsql/#sum)
`sum(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns the sum per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

#### sum2 [#](https://docs.victoriametrics.com/metricsql/#sum2)
`sum2(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which calculates the sum of squares per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

#### topk [#](https://docs.victoriametrics.com/metricsql/#topk)
`topk(k, q)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` points with the biggest values across all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp.

This function is supported by PromQL.

See also [bottomk](https://docs.victoriametrics.com/metricsql/#bottomk), [topk_max](https://docs.victoriametrics.com/metricsql/#topk_max) and [topk_last](https://docs.victoriametrics.com/metricsql/#topk_last).

#### topk_avg [#](https://docs.victoriametrics.com/metricsql/#topk_avg)
`topk_avg(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the biggest averages. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `topk_avg(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the biggest averages plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [bottomk_avg](https://docs.victoriametrics.com/metricsql/#bottomk_avg).

#### topk_last [#](https://docs.victoriametrics.com/metricsql/#topk_last)
`topk_last(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the biggest last values. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `topk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the biggest maximums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [bottomk_last](https://docs.victoriametrics.com/metricsql/#bottomk_last).

#### topk_max [#](https://docs.victoriametrics.com/metricsql/#topk_max)
`topk_max(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the biggest maximums. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `topk_max(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the biggest maximums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [bottomk_max](https://docs.victoriametrics.com/metricsql/#bottomk_max).

#### topk_median [#](https://docs.victoriametrics.com/metricsql/#topk_median)
`topk_median(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the biggest medians. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `topk_median(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the biggest medians plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [bottomk_median](https://docs.victoriametrics.com/metricsql/#bottomk_median).

#### topk_min [#](https://docs.victoriametrics.com/metricsql/#topk_min)
`topk_min(k, q, "other_label=other_value")` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns up to `k` time series from `q` with the biggest minimums. If an optional `other_label=other_value` arg is set, then the sum of the remaining time series is returned with the given label. For example, `topk_min(3, sum(process_resident_memory_bytes) by (job), "job=other")` would return up to 3 time series with the biggest minimums plus a time series with `{job="other"}` label with the sum of the remaining series if any.

See also [bottomk_min](https://docs.victoriametrics.com/metricsql/#bottomk_min).

#### zscore [#](https://docs.victoriametrics.com/metricsql/#zscore)
`zscore(q) by (group_labels)` is [aggregate function](https://docs.victoriametrics.com/metricsql/#aggregate-functions), which returns [z-score](https://en.wikipedia.org/wiki/Standard_score) values per each `group_labels` for all the time series returned by `q`. The aggregate is calculated individually per each group of points with the same timestamp. This function is useful for detecting anomalies in the group of related time series.

See also [zscore_over_time](https://docs.victoriametrics.com/metricsql/#zscore_over_time), [range_trim_zscore](https://docs.victoriametrics.com/metricsql/#range_trim_zscore) and [outliers_iqr](https://docs.victoriametrics.com/metricsql/#outliers_iqr).

