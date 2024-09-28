---
title: 数值转换
weight: 4
---

**Transform functions** calculate transformations over [rollup results](https://docs.victoriametrics.com/metricsql/#rollup-functions). For example, `abs(delta(temperature[24h]))` calculates the absolute value for every point of every time series returned from the rollup `delta(temperature[24h])`.

Additional details:

+ If transform function is applied directly to a [series selector](https://docs.victoriametrics.com/keyconcepts/#filtering), then the [default_rollup()](https://docs.victoriametrics.com/metricsql/#default_rollup) function is automatically applied before calculating the transformations. For example, `abs(temperature)` is implicitly transformed to `abs(default_rollup(temperature))`.
+ All the transform functions accept optional `keep_metric_names` modifier. If it is set, then the function doesn’t drop metric names from the resulting time series. See [these docs](https://docs.victoriametrics.com/metricsql/#keep_metric_names).

See also [implicit query conversions](https://docs.victoriametrics.com/metricsql/#implicit-query-conversions).

#### abs [#](https://docs.victoriametrics.com/metricsql/#abs)
`abs(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the absolute value for every point of every time series returned by `q`.

This function is supported by PromQL.

#### absent [#](https://docs.victoriametrics.com/metricsql/#absent)
`absent(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns 1 if `q` has no points. Otherwise, returns an empty result.

This function is supported by PromQL.

See also [absent_over_time](https://docs.victoriametrics.com/metricsql/#absent_over_time).

#### acos [#](https://docs.victoriametrics.com/metricsql/#acos)
`acos(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse cosine](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [asin](https://docs.victoriametrics.com/metricsql/#asin) and [cos](https://docs.victoriametrics.com/metricsql/#cos).

#### acosh [#](https://docs.victoriametrics.com/metricsql/#acosh)
`acosh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse hyperbolic cosine](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_cosine) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [sinh](https://docs.victoriametrics.com/metricsql/#cosh).

#### asin [#](https://docs.victoriametrics.com/metricsql/#asin)
`asin(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse sine](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [acos](https://docs.victoriametrics.com/metricsql/#acos) and [sin](https://docs.victoriametrics.com/metricsql/#sin).

#### asinh [#](https://docs.victoriametrics.com/metricsql/#asinh)
`asinh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse hyperbolic sine](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_sine) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [sinh](https://docs.victoriametrics.com/metricsql/#sinh).

#### atan [#](https://docs.victoriametrics.com/metricsql/#atan)
`atan(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse tangent](https://en.wikipedia.org/wiki/Inverse_trigonometric_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [tan](https://docs.victoriametrics.com/metricsql/#tan).

#### atanh [#](https://docs.victoriametrics.com/metricsql/#atanh)
`atanh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [inverse hyperbolic tangent](https://en.wikipedia.org/wiki/Inverse_hyperbolic_functions#Inverse_hyperbolic_tangent) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [tanh](https://docs.victoriametrics.com/metricsql/#tanh).

#### bitmap_and [#](https://docs.victoriametrics.com/metricsql/#bitmap_and)
`bitmap_and(q, mask)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates bitwise `v & mask` for every `v` point of every time series returned from `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

#### bitmap_or [#](https://docs.victoriametrics.com/metricsql/#bitmap_or)
`bitmap_or(q, mask)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates bitwise `v | mask` for every `v` point of every time series returned from `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

#### bitmap_xor [#](https://docs.victoriametrics.com/metricsql/#bitmap_xor)
`bitmap_xor(q, mask)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates bitwise `v ^ mask` for every `v` point of every time series returned from `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

#### buckets_limit [#](https://docs.victoriametrics.com/metricsql/#buckets_limit)
`buckets_limit(limit, buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which limits the number of [histogram buckets](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) to the given `limit`.

See also [prometheus_buckets](https://docs.victoriametrics.com/metricsql/#prometheus_buckets) and [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile).

#### ceil [#](https://docs.victoriametrics.com/metricsql/#ceil)
`ceil(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which rounds every point for every time series returned by `q` to the upper nearest integer.

This function is supported by PromQL.

See also [floor](https://docs.victoriametrics.com/metricsql/#floor) and [round](https://docs.victoriametrics.com/metricsql/#round).

#### clamp [#](https://docs.victoriametrics.com/metricsql/#clamp)
`clamp(q, min, max)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which clamps every point for every time series returned by `q` with the given `min` and `max` values.

This function is supported by PromQL.

See also [clamp_min](https://docs.victoriametrics.com/metricsql/#clamp_min) and [clamp_max](https://docs.victoriametrics.com/metricsql/#clamp_max).

#### clamp_max [#](https://docs.victoriametrics.com/metricsql/#clamp_max)
`clamp_max(q, max)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which clamps every point for every time series returned by `q` with the given `max` value.

This function is supported by PromQL.

See also [clamp](https://docs.victoriametrics.com/metricsql/#clamp) and [clamp_min](https://docs.victoriametrics.com/metricsql/#clamp_min).

#### clamp_min [#](https://docs.victoriametrics.com/metricsql/#clamp_min)
`clamp_min(q, min)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which clamps every point for every time series returned by `q` with the given `min` value.

This function is supported by PromQL.

See also [clamp](https://docs.victoriametrics.com/metricsql/#clamp) and [clamp_max](https://docs.victoriametrics.com/metricsql/#clamp_max).

#### cos [#](https://docs.victoriametrics.com/metricsql/#cos)
`cos(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `cos(v)` for every `v` point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [sin](https://docs.victoriametrics.com/metricsql/#sin).

#### cosh [#](https://docs.victoriametrics.com/metricsql/#cosh)
`cosh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [hyperbolic cosine](https://en.wikipedia.org/wiki/Hyperbolic_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [acosh](https://docs.victoriametrics.com/metricsql/#acosh).

#### day_of_month [#](https://docs.victoriametrics.com/metricsql/#day_of_month)
`day_of_month(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the day of month for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[1...31]`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [day_of_week](https://docs.victoriametrics.com/metricsql/#day_of_week) and [day_of_year](https://docs.victoriametrics.com/metricsql/#day_of_year).

#### day_of_week [#](https://docs.victoriametrics.com/metricsql/#day_of_week)
`day_of_week(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the day of week for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[0...6]`, where `0` means Sunday and `6` means Saturday.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [day_of_month](https://docs.victoriametrics.com/metricsql/#day_of_month) and [day_of_year](https://docs.victoriametrics.com/metricsql/#day_of_year).

#### day_of_year [#](https://docs.victoriametrics.com/metricsql/#day_of_year)
`day_of_year(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the day of year for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[1...365]` for non-leap years, and `[1 to 366]` in leap years.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [day_of_week](https://docs.victoriametrics.com/metricsql/#day_of_week) and [day_of_month](https://docs.victoriametrics.com/metricsql/#day_of_month).

#### days_in_month [#](https://docs.victoriametrics.com/metricsql/#days_in_month)
`days_in_month(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the number of days in the month identified by every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[28...31]`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### deg [#](https://docs.victoriametrics.com/metricsql/#deg)
`deg(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which converts [Radians to degrees](https://en.wikipedia.org/wiki/Radian#Conversions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [rad](https://docs.victoriametrics.com/metricsql/#rad).

#### drop_empty_series [#](https://docs.victoriametrics.com/metricsql/#drop_empty_series)
`drop_empty_series(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which drops empty series from `q`.

This function can be used when `default` operator should be applied only to non-empty series. For example, `drop_empty_series(temperature < 30) default 42` returns series, which have at least a single sample smaller than 30 on the selected time range, while filling gaps in the returned series with 42.

On the other hand `(temperature < 30) default 40` returns all the `temperature` series, even if they have no samples smaller than 30, by replacing all the values bigger or equal to 30 with 40.

#### end [#](https://docs.victoriametrics.com/metricsql/#end)
`end()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the unix timestamp in seconds for the last point. It is known as `end` query arg passed to [/api/v1/query_range](https://docs.victoriametrics.com/keyconcepts/#range-query).

See also [start](https://docs.victoriametrics.com/metricsql/#start), [time](https://docs.victoriametrics.com/metricsql/#time) and [now](https://docs.victoriametrics.com/metricsql/#now).

#### exp [#](https://docs.victoriametrics.com/metricsql/#exp)
`exp(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the `e^v` for every point `v` of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [ln](https://docs.victoriametrics.com/metricsql/#ln).

#### floor [#](https://docs.victoriametrics.com/metricsql/#floor)
`floor(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which rounds every point for every time series returned by `q` to the lower nearest integer.

This function is supported by PromQL.

See also [ceil](https://docs.victoriametrics.com/metricsql/#ceil) and [round](https://docs.victoriametrics.com/metricsql/#round).

#### histogram_avg [#](https://docs.victoriametrics.com/metricsql/#histogram_avg)
`histogram_avg(buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the average value for the given `buckets`. It can be used for calculating the average over the given time range across multiple time series. For example, `histogram_avg(sum(histogram_over_time(response_time_duration_seconds[5m])) by (vmrange,job))` would return the average response time per each `job` over the last 5 minutes.

#### histogram_quantile [#](https://docs.victoriametrics.com/metricsql/#histogram_quantile)
`histogram_quantile(phi, buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates `phi`-[percentile](https://en.wikipedia.org/wiki/Percentile) over the given [histogram buckets](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350). `phi` must be in the range `[0...1]`. For example, `histogram_quantile(0.5, sum(rate(http_request_duration_seconds_bucket[5m])) by (le))` would return median request duration for all the requests during the last 5 minutes.

The function accepts optional third arg - `boundsLabel`. In this case it returns `lower` and `upper` bounds for the estimated percentile with the given `boundsLabel` label. See [this issue for details](https://github.com/prometheus/prometheus/issues/5706).

When the [percentile](https://en.wikipedia.org/wiki/Percentile) is calculated over multiple histograms, then all the input histograms **must** have buckets with identical boundaries, e.g. they must have the same set of `le` or `vmrange` labels. Otherwise, the returned result may be invalid. See [this issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/3231) for details.

This function is supported by PromQL (except of the `boundLabel` arg).

See also [histogram_quantiles](https://docs.victoriametrics.com/metricsql/#histogram_quantiles), [histogram_share](https://docs.victoriametrics.com/metricsql/#histogram_share) and [quantile](https://docs.victoriametrics.com/metricsql/#quantile).

#### histogram_quantiles [#](https://docs.victoriametrics.com/metricsql/#histogram_quantiles)
`histogram_quantiles("phiLabel", phi1, ..., phiN, buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the given `phi*`-quantiles over the given [histogram buckets](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350). Argument `phi*` must be in the range `[0...1]`. For example, `histogram_quantiles('le', 0.3, 0.5, sum(rate(http_request_duration_seconds_bucket[5m]) by (le))`. Each calculated quantile is returned in a separate time series with the corresponding `{phiLabel="phi*"}` label.

See also [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile).

#### histogram_share [#](https://docs.victoriametrics.com/metricsql/#histogram_share)
`histogram_share(le, buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the share (in the range `[0...1]`) for `buckets` that fall below `le`. This function is useful for calculating SLI and SLO. This is inverse to [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile).

The function accepts optional third arg - `boundsLabel`. In this case it returns `lower` and `upper` bounds for the estimated share with the given `boundsLabel` label.

#### histogram_stddev [#](https://docs.victoriametrics.com/metricsql/#histogram_stddev)
`histogram_stddev(buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates standard deviation for the given `buckets`.

#### histogram_stdvar [#](https://docs.victoriametrics.com/metricsql/#histogram_stdvar)
`histogram_stdvar(buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates standard variance for the given `buckets`. It can be used for calculating standard deviation over the given time range across multiple time series. For example, `histogram_stdvar(sum(histogram_over_time(temperature[24])) by (vmrange,country))` would return standard deviation for the temperature per each country over the last 24 hours.

#### hour [#](https://docs.victoriametrics.com/metricsql/#hour)
`hour(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the hour for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[0...23]`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### interpolate [#](https://docs.victoriametrics.com/metricsql/#interpolate)
`interpolate(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which fills gaps with linearly interpolated values calculated from the last and the next non-empty points per each time series returned by `q`.

See also [keep_last_value](https://docs.victoriametrics.com/metricsql/#keep_last_value) and [keep_next_value](https://docs.victoriametrics.com/metricsql/#keep_next_value).

#### keep_last_value [#](https://docs.victoriametrics.com/metricsql/#keep_last_value)
`keep_last_value(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which fills gaps with the value of the last non-empty point in every time series returned by `q`.

See also [keep_next_value](https://docs.victoriametrics.com/metricsql/#keep_next_value) and [interpolate](https://docs.victoriametrics.com/metricsql/#interpolate).

#### keep_next_value [#](https://docs.victoriametrics.com/metricsql/#keep_next_value)
`keep_next_value(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which fills gaps with the value of the next non-empty point in every time series returned by `q`.

See also [keep_last_value](https://docs.victoriametrics.com/metricsql/#keep_last_value) and [interpolate](https://docs.victoriametrics.com/metricsql/#interpolate).

#### limit_offset [#](https://docs.victoriametrics.com/metricsql/#limit_offset)
`limit_offset(limit, offset, q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which skips `offset` time series from series returned by `q` and then returns up to `limit` of the remaining time series per each group.

This allows implementing simple paging for `q` time series. See also [limitk](https://docs.victoriametrics.com/metricsql/#limitk).

#### ln [#](https://docs.victoriametrics.com/metricsql/#ln)
`ln(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates `ln(v)` for every point `v` of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [exp](https://docs.victoriametrics.com/metricsql/#exp) and [log2](https://docs.victoriametrics.com/metricsql/#log2).

#### log2 [#](https://docs.victoriametrics.com/metricsql/#log2)
`log2(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates `log2(v)` for every point `v` of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [log10](https://docs.victoriametrics.com/metricsql/#log10) and [ln](https://docs.victoriametrics.com/metricsql/#ln).

#### log10 [#](https://docs.victoriametrics.com/metricsql/#log10)
`log10(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates `log10(v)` for every point `v` of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [log2](https://docs.victoriametrics.com/metricsql/#log2) and [ln](https://docs.victoriametrics.com/metricsql/#ln).

#### minute [#](https://docs.victoriametrics.com/metricsql/#minute)
`minute(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the minute for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[0...59]`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### month [#](https://docs.victoriametrics.com/metricsql/#month)
`month(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the month for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps. The returned values are in the range `[1...12]`, where `1` means January and `12` means December.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### now [#](https://docs.victoriametrics.com/metricsql/#now)
`now()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the current timestamp as a floating-point value in seconds.

See also [time](https://docs.victoriametrics.com/metricsql/#time).

#### pi [#](https://docs.victoriametrics.com/metricsql/#pi)
`pi()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [Pi number](https://en.wikipedia.org/wiki/Pi).

This function is supported by PromQL.

#### rad [#](https://docs.victoriametrics.com/metricsql/#rad)
`rad(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which converts [degrees to Radians](https://en.wikipedia.org/wiki/Radian#Conversions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

See also [deg](https://docs.victoriametrics.com/metricsql/#deg).

#### prometheus_buckets [#](https://docs.victoriametrics.com/metricsql/#prometheus_buckets)
`prometheus_buckets(buckets)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which converts [VictoriaMetrics histogram buckets](https://valyala.medium.com/improving-histogram-usability-for-prometheus-and-grafana-bc7e5df0e350) with `vmrange` labels to Prometheus histogram buckets with `le` labels. This may be useful for building heatmaps in Grafana.

See also [histogram_quantile](https://docs.victoriametrics.com/metricsql/#histogram_quantile) and [buckets_limit](https://docs.victoriametrics.com/metricsql/#buckets_limit).

#### rand [#](https://docs.victoriametrics.com/metricsql/#rand)
`rand(seed)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns pseudo-random numbers on the range `[0...1]` with even distribution. Optional `seed` can be used as a seed for pseudo-random number generator.

See also [rand_normal](https://docs.victoriametrics.com/metricsql/#rand_normal) and [rand_exponential](https://docs.victoriametrics.com/metricsql/#rand_exponential).

#### rand_exponential [#](https://docs.victoriametrics.com/metricsql/#rand_exponential)
`rand_exponential(seed)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns pseudo-random numbers with [exponential distribution](https://en.wikipedia.org/wiki/Exponential_distribution). Optional `seed` can be used as a seed for pseudo-random number generator.

See also [rand](https://docs.victoriametrics.com/metricsql/#rand) and [rand_normal](https://docs.victoriametrics.com/metricsql/#rand_normal).

#### rand_normal [#](https://docs.victoriametrics.com/metricsql/#rand_normal)
`rand_normal(seed)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns pseudo-random numbers with [normal distribution](https://en.wikipedia.org/wiki/Normal_distribution). Optional `seed` can be used as a seed for pseudo-random number generator.

See also [rand](https://docs.victoriametrics.com/metricsql/#rand) and [rand_exponential](https://docs.victoriametrics.com/metricsql/#rand_exponential).

#### range_avg [#](https://docs.victoriametrics.com/metricsql/#range_avg)
`range_avg(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the avg value across points per each time series returned by `q`.

#### range_first [#](https://docs.victoriametrics.com/metricsql/#range_first)
`range_first(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the value for the first point per each time series returned by `q`.

#### range_last [#](https://docs.victoriametrics.com/metricsql/#range_last)
`range_last(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the value for the last point per each time series returned by `q`.

#### range_linear_regression [#](https://docs.victoriametrics.com/metricsql/#range_linear_regression)
`range_linear_regression(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates [simple linear regression](https://en.wikipedia.org/wiki/Simple_linear_regression) over the selected time range per each time series returned by `q`. This function is useful for capacity planning and predictions.

#### range_mad [#](https://docs.victoriametrics.com/metricsql/#range_mad)
`range_mad(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the [median absolute deviation](https://en.wikipedia.org/wiki/Median_absolute_deviation) across points per each time series returned by `q`.

See also [mad](https://docs.victoriametrics.com/metricsql/#mad) and [mad_over_time](https://docs.victoriametrics.com/metricsql/#mad_over_time).

#### range_max [#](https://docs.victoriametrics.com/metricsql/#range_max)
`range_max(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the max value across points per each time series returned by `q`.

#### range_median [#](https://docs.victoriametrics.com/metricsql/#range_median)
`range_median(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the median value across points per each time series returned by `q`.

#### range_min [#](https://docs.victoriametrics.com/metricsql/#range_min)
`range_min(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the min value across points per each time series returned by `q`.

#### range_normalize [#](https://docs.victoriametrics.com/metricsql/#range_normalize)
`range_normalize(q1, ...)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which normalizes values for time series returned by `q1, ...` into `[0 ... 1]` range. This function is useful for correlating time series with distinct value ranges.

See also [share](https://docs.victoriametrics.com/metricsql/#share).

#### range_quantile [#](https://docs.victoriametrics.com/metricsql/#range_quantile)
`range_quantile(phi, q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `phi`-quantile across points per each time series returned by `q`. `phi` must be in the range `[0...1]`.

#### range_stddev [#](https://docs.victoriametrics.com/metricsql/#range_stddev)
`range_stddev(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates [standard deviation](https://en.wikipedia.org/wiki/Standard_deviation) per each time series returned by `q` on the selected time range.

#### range_stdvar [#](https://docs.victoriametrics.com/metricsql/#range_stdvar)
`range_stdvar(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates [standard variance](https://en.wikipedia.org/wiki/Variance) per each time series returned by `q` on the selected time range.

#### range_sum [#](https://docs.victoriametrics.com/metricsql/#range_sum)
`range_sum(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the sum of points per each time series returned by `q`.

#### range_trim_outliers [#](https://docs.victoriametrics.com/metricsql/#range_trim_outliers)
`range_trim_outliers(k, q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which drops points located farther than `k*range_mad(q)` from the `range_median(q)`. E.g. it is equivalent to the following query: `q ifnot (abs(q - range_median(q)) > k*range_mad(q))`.

See also [range_trim_spikes](https://docs.victoriametrics.com/metricsql/#range_trim_spikes) and [range_trim_zscore](https://docs.victoriametrics.com/metricsql/#range_trim_zscore).

#### range_trim_spikes [#](https://docs.victoriametrics.com/metricsql/#range_trim_spikes)
`range_trim_spikes(phi, q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which drops `phi` percent of biggest spikes from time series returned by `q`. The `phi` must be in the range `[0..1]`, where `0` means `0%` and `1` means `100%`.

See also [range_trim_outliers](https://docs.victoriametrics.com/metricsql/#range_trim_outliers) and [range_trim_zscore](https://docs.victoriametrics.com/metricsql/#range_trim_zscore).

#### range_trim_zscore [#](https://docs.victoriametrics.com/metricsql/#range_trim_zscore)
`range_trim_zscore(z, q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which drops points located farther than `z*range_stddev(q)` from the `range_avg(q)`. E.g. it is equivalent to the following query: `q ifnot (abs(q - range_avg(q)) > z*range_avg(q))`.

See also [range_trim_outliers](https://docs.victoriametrics.com/metricsql/#range_trim_outliers) and [range_trim_spikes](https://docs.victoriametrics.com/metricsql/#range_trim_spikes).

#### range_zscore [#](https://docs.victoriametrics.com/metricsql/#range_zscore)
`range_zscore(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates [z-score](https://en.wikipedia.org/wiki/Standard_score) for points returned by `q`, e.g. it is equivalent to the following query: `(q - range_avg(q)) / range_stddev(q)`.

#### remove_resets [#](https://docs.victoriametrics.com/metricsql/#remove_resets)
`remove_resets(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which removes counter resets from time series returned by `q`.

#### round [#](https://docs.victoriametrics.com/metricsql/#round)
`round(q, nearest)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which rounds every point of every time series returned by `q` to the `nearest` multiple. If `nearest` is missing then the rounding is performed to the nearest integer.

This function is supported by PromQL.

See also [floor](https://docs.victoriametrics.com/metricsql/#floor) and [ceil](https://docs.victoriametrics.com/metricsql/#ceil).

#### ru [#](https://docs.victoriametrics.com/metricsql/#ru)
`ru(free, max)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates resource utilization in the range `[0%...100%]` for the given `free` and `max` resources. For instance, `ru(node_memory_MemFree_bytes, node_memory_MemTotal_bytes)` returns memory utilization over [node_exporter](https://github.com/prometheus/node_exporter) metrics.

#### running_avg [#](https://docs.victoriametrics.com/metricsql/#running_avg)
`running_avg(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the running avg per each time series returned by `q`.

#### running_max [#](https://docs.victoriametrics.com/metricsql/#running_max)
`running_max(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the running max per each time series returned by `q`.

#### running_min [#](https://docs.victoriametrics.com/metricsql/#running_min)
`running_min(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the running min per each time series returned by `q`.

#### running_sum [#](https://docs.victoriametrics.com/metricsql/#running_sum)
`running_sum(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates the running sum per each time series returned by `q`.

#### scalar [#](https://docs.victoriametrics.com/metricsql/#scalar)
`scalar(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `q` if `q` contains only a single time series. Otherwise, it returns nothing.

This function is supported by PromQL.

#### sgn [#](https://docs.victoriametrics.com/metricsql/#sgn)
`sgn(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `1` if `v>0`, `-1` if `v<0` and `0` if `v==0` for every point `v` of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### sin [#](https://docs.victoriametrics.com/metricsql/#sin)
`sin(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `sin(v)` for every `v` point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by MetricsQL.

See also [cos](https://docs.victoriametrics.com/metricsql/#cos).

#### sinh [#](https://docs.victoriametrics.com/metricsql/#sinh)
`sinh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [hyperbolic sine](https://en.wikipedia.org/wiki/Hyperbolic_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by MetricsQL.

See also [cosh](https://docs.victoriametrics.com/metricsql/#cosh).

#### tan [#](https://docs.victoriametrics.com/metricsql/#tan)
`tan(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `tan(v)` for every `v` point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by MetricsQL.

See also [atan](https://docs.victoriametrics.com/metricsql/#atan).

#### tanh [#](https://docs.victoriametrics.com/metricsql/#tanh)
`tanh(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns [hyperbolic tangent](https://en.wikipedia.org/wiki/Hyperbolic_functions) for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by MetricsQL.

See also [atanh](https://docs.victoriametrics.com/metricsql/#atanh).

#### smooth_exponential [#](https://docs.victoriametrics.com/metricsql/#smooth_exponential)
`smooth_exponential(q, sf)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which smooths points per each time series returned by `q` using [exponential moving average](https://en.wikipedia.org/wiki/Moving_average#Exponential_moving_average) with the given smooth factor `sf`.

#### sort [#](https://docs.victoriametrics.com/metricsql/#sort)
`sort(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which sorts series in ascending order by the last point in every time series returned by `q`.

This function is supported by PromQL.

See also [sort_desc](https://docs.victoriametrics.com/metricsql/#sort_desc) and [sort_by_label](https://docs.victoriametrics.com/metricsql/#sort_by_label).

#### sort_desc [#](https://docs.victoriametrics.com/metricsql/#sort_desc)
`sort_desc(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which sorts series in descending order by the last point in every time series returned by `q`.

This function is supported by PromQL.

See also [sort](https://docs.victoriametrics.com/metricsql/#sort) and [sort_by_label](https://docs.victoriametrics.com/metricsql/#sort_by_label_desc).

#### sqrt [#](https://docs.victoriametrics.com/metricsql/#sqrt)
`sqrt(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which calculates square root for every point of every time series returned by `q`.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

#### start [#](https://docs.victoriametrics.com/metricsql/#start)
`start()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns unix timestamp in seconds for the first point.

It is known as `start` query arg passed to [/api/v1/query_range](https://docs.victoriametrics.com/keyconcepts/#range-query).

See also [end](https://docs.victoriametrics.com/metricsql/#end), [time](https://docs.victoriametrics.com/metricsql/#time) and [now](https://docs.victoriametrics.com/metricsql/#now).

#### step [#](https://docs.victoriametrics.com/metricsql/#step)
`step()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the step in seconds (aka interval) between the returned points. It is known as `step` query arg passed to [/api/v1/query_range](https://docs.victoriametrics.com/keyconcepts/#range-query).

See also [start](https://docs.victoriametrics.com/metricsql/#start) and [end](https://docs.victoriametrics.com/metricsql/#end).

#### time [#](https://docs.victoriametrics.com/metricsql/#time)
`time()` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns unix timestamp for every returned point.

This function is supported by PromQL.

See also [timestamp](https://docs.victoriametrics.com/metricsql/#timestamp), [now](https://docs.victoriametrics.com/metricsql/#now), [start](https://docs.victoriametrics.com/metricsql/#start) and [end](https://docs.victoriametrics.com/metricsql/#end).

#### timezone_offset [#](https://docs.victoriametrics.com/metricsql/#timezone_offset)
`timezone_offset(tz)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns offset in seconds for the given timezone `tz` relative to UTC. This can be useful when combining with datetime-related functions. For example, `day_of_week(time()+timezone_offset("America/Los_Angeles"))` would return weekdays for `America/Los_Angeles` time zone.

Special `Local` time zone can be used for returning an offset for the time zone set on the host where VictoriaMetrics runs.

See [the list of supported timezones](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).

#### ttf [#](https://docs.victoriametrics.com/metricsql/#ttf)
`ttf(free)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which estimates the time in seconds needed to exhaust `free` resources. For instance, `ttf(node_filesystem_avail_byte)` returns the time to storage space exhaustion. This function may be useful for capacity planning.

#### union [#](https://docs.victoriametrics.com/metricsql/#union)
`union(q1, ..., qN)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns a union of time series returned from `q1`, …, `qN`. The `union` function name can be skipped - the following queries are equivalent: `union(q1, q2)` and `(q1, q2)`.

It is expected that each `q*` query returns time series with unique sets of labels. Otherwise, only the first time series out of series with identical set of labels is returned. Use [alias](https://docs.victoriametrics.com/metricsql/#alias) and [label_set](https://docs.victoriametrics.com/metricsql/#label_set) functions for giving unique labelsets per each `q*` query:

#### vector [#](https://docs.victoriametrics.com/metricsql/#vector)
`vector(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns `q`, e.g. it does nothing in MetricsQL.

This function is supported by PromQL.

#### year [#](https://docs.victoriametrics.com/metricsql/#year)
`year(q)` is a [transform function](https://docs.victoriametrics.com/metricsql/#transform-functions), which returns the year for every point of every time series returned by `q`. It is expected that `q` returns unix timestamps.

Metric names are stripped from the resulting series. Add [keep_metric_names](https://docs.victoriametrics.com/metricsql/#keep_metric_names) modifier in order to keep metric names.

This function is supported by PromQL.

