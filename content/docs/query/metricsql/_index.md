---
title: MetricQL
weight: 1
---

VictoriaMetrics提供了一种特殊的查询语言，用于执行查询语句 - MetricsQL。它是一个类似 [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics) 的查询语言，具有强大的函数和功能集，专门用于处理时间序列数据。MetricsQL完全兼容PromQL，因此他们之间大部分概念都是共享的。

所以，使用VictoriaMetrics替换Prometheus后，由Prometheus数据源创建的Grafana仪表板不会收到任何影响。然而，这两种语言之间存在[一定的差异](#diff)。

一个[独立的 MetricQL 库](https://godoc.org/github.com/VictoriaMetrics/metricsql)可用于在其他应用中解析 MetricQL 语句。

如果你对 PromQL 不熟，建议阅读一下[这篇文章]({{< relref "promql.md" >}})。

MetricsQL 在以下功能上与 PromQL 实现方式不同，这些不同改进了用户体验：

+ MetricsQL在计算范围函数（如`rate`和`increase`）时，考虑了方括号中窗口之前的上一个点。这样可以返回用户对于`increase(metric[$__interval])`查询所期望的精确结果，而不是Prometheus为此类查询返回的不完整结果。 
+ MetricsQL不会推断范围函数的结果。这解决了 [Prometheus 中存在的问题](https://github.com/prometheus/prometheus/issues/3746)。有关VictoriaMetrics和Prometheus计算`rate`和`increase`的技术细节，请参阅 [issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1215#issuecomment-850305711)。 
+ MetricsQL对于 step 小于抓取间隔的rate查询返回预期非空响应。这解决了 [Grafana 中存在的问题](https://github.com/grafana/grafana/issues/11451)。还请参阅[这篇文章](https://www.percona.com/blog/2020/02/28/better-prometheus-rate-function-with-victoriametrics/)。
+ MetricsQL将`scalar`类型与没有 Label 的`instant vector`视为相同，因为这些类型之间微小差异通常会让用户感到困惑。有关详细信息，请参阅[相应的 Prometheus 文档](https://prometheus.io/docs/prometheus/latest/querying/basics/#expression-language-data-types)。 
+ MetricsQL从输出中删除所有`NaN`值，因此一些查询（例如`(-1)^0.5`）在VictoriaMetrics中返回空结果，在Prometheus中则返回一系列NaN值。请注意，Grafana不会为NaN值绘制任何线条或点，因此最终结果在VictoriaMetrics和Prometheus上看起来是相同的。 在应用函数后，
+ MetricsQL保留指标名称，并且该函数不改变原始时间序列的含义。例如，`min_over_time(foo)`或`round(foo)`将在结果中保留`foo`指标名称。有关详细信息，请参阅[issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/674)。

## MetricQL 功能特性
MetricsQL 除了实现了 PromQL 的所有功能，还额外增加了下面的特性，这些特性目的解决实际应用场景中遇到的问题。如果你认为 MetricsQL 中缺失一些有用的功能，可以[提交一个 Feature Request](https://github.com/VictoriaMetrics/VictoriaMetrics/issues)

这些特性可以在 [VictoriaMetrics playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/) 进行验证，也可以在你自己的 [VictoriaMetrics 实例]({{< relref "../../quickstart.md" >}})上验证。

MetricsQL 特性列表:

+ Graphite-compatible filters can be passed via `{__graphite__="foo.*.bar"}` syntax. See [these docs](https://docs.victoriametrics.com/#selecting-graphite-metrics). VictoriaMetrics also can be used as Graphite datasource in Grafana. See [these docs](https://docs.victoriametrics.com/#graphite-api-usage) for details. See also [label_graphite_group](https://docs.victoriametrics.com/MetricsQL.html#label_graphite_group) function, which can be used for extracting the given groups from Graphite metric name.
- 支持兼容 Graphite 过滤器的写法，比如`{__graphite__="foo.*.bar"}`。VictoriaMetrics 支持使用`__graphite__`伪 Label 从 VictoriaMetrics 中使用兼容 Graphite 的过滤器查询时序数据。比如，`{__graphite__="foo.*.bar"}`等同于`{__name__=~"foo[.][^.]*[.]bar"}`，但它的性能更高并且很容易使用。更多内容请阅读 [Graphite 模糊匹配](https://graphite.readthedocs.io/en/latest/render_api.html#paths-and-wildcards)。因此可在 Grafana 中 VictoriaMetrics 可以作为 Graphite 数据源。
- [`label_graphite_group`]()可用于从 Graphite 指标名中解析出分组。
- `__graphite__`伪标签支持正则过滤，比如`(value1|...|valueN)`。他们会被转换成在 Graphite 中使用的`{value1,...,valueN}`语法。这允许在 Grafana 模板变量中使用多值传递给`__graphite__`。例如，Grafana 将 `{__graphite__=~"foo.($bar).baz"}`扩展成了`{__graphite__=~"foo.(x|y).baz"}`，如果`$bar`模板变量中包含`x`和`y`两个值。在这个例子中，语句会被在执行前自动被转换成`{__graphite__=~"foo.{x,y}.baz"}`。
- 中括号`[]`中的回溯窗口可以被省略。VictoriaMetrics 会基于当前的步长自动设置回溯窗口（比如传递到[/api/v1/query_range]({{< relref "../../quickstart.md#range-query" >}})中的`step`参数)。例如，`rate(node_network_receive_bytes_total)`在 VictoriaMetrics 中是合法的，在使用 Grafana 时，它等同于`rate(node_network_receive_bytes_total[$__interval])`。
+ [Series 选择器]({{< relref "./basic.md#filter" >}}) 接收多个`or`过滤器。比如，`{env="prod",job="a" or env="dev",job="b"}`使用`{env="prod",job="a"}`或`{env="dev",job="b"}`过滤 Series. 更多详情看[这些文档]({{< relref "./basic.md#or-filter" >}})。
+ [聚合函数]({{< relref "./functions/aggregation.md" >}}) 接收多个参数。例如，`avg(q1, q2, q3)`会将`q1`,`q2`和`q3`返回的所有 Timeseries 数据点计算平均值。
+ [@ 修改器]({{< relref "./basic.md#modifier" >}}) 可以放在语句中的任何地方。例如，`sum(foo) @ end()` 在`[start ... end]`查询的数据中，`end`时间点上的数据计算`sum(foo)`。
+ 任意子表达式可以应用在 [@ modifier]({{< relref "./basic.md#modifier" >}}) 上，比如，`foo @ (end() - 1h)`在`[start ... end]`查询的数据中，`end -1 hour`时间点上的数据计算`sum(foo)`。
+ [offset]({{< relref "./basic.md#offset-modifier" >}})， 中括号`[]`中的回溯窗口和[子查询](#subquery)里的`step`值会引用当前的步长，该步长会通过 Grafana 的`$__interaval`和`[Ni]`语法传递。例如，`rate(metric[10i] offset 5i)`会返回前10个步长时间内每秒增长量，时间偏移5个步长。
+ [offset]({{< relref "./basic.md#offset-modifier" >}}) 可以放在语句的任何地方。比如`sum(foo) offset 24h`。
+ 中括号`[]`内的回溯窗口和 [offset]({{< relref "./basic.md#offset-modifier" >}}) 可以是小数。比如，`rate(node_network_receive_bytes_total[1.5m] offset 0.5d)`。
+ 时间段表达式后缀是可以省略的，默认单位是秒，比如，`rate(m[300] offset 1800)` 等同于 `rate(m[5m]) offset 30m`。
+ 时间段可以在语句的任何地方使用。比如，`sum_over_time(m[1h]) / 1h` 等同于 `sum_over_time(m[1h]) / 3600`。
+ 数字类型值可以使用 `K`, `Ki`, `M`, `Mi`, `G`, `Gi`, `T` 和 `Ti` 后缀。例如，`8K` 等同于 `8000`, `1.2Mi` 等同于 `1.2*1024*1024`.
+ 所有的列表中最后的的逗号`,`字符是可接受的 - Label 过滤器，函数参数，以及 `WITH` 模板表达式。例如，这些从查询都是允许的：`m{foo="bar",}`, `f(a, b,)`, `WITH (x=y,) x`。这回简化查询语句的自动生成。
+ Metric 名和 Label 名允许使用 unicode 字符。例如`температура{город="Киев"}`也是合法的。
+ Metric 名和 Label 名允许包含转义字符。比如`foo\-bar{baz\=aa="b"}`是合法的表达式。 它返回的 Timeseries 指标名为`foot-bar`，包含一个 Label，其名是`baz=aa`，值为`b`，此外，下面的转义也是支持的：
    - `\xXX`, 这里`XX`代表 ascii 码表示的字符。
    - `\uXXXX`, 这里`XXXX`是用 unicode 编码表示的字符。
+ 聚合函数支持使用`limit N`后缀， 其目的是限制输出的 series 数量。例如，`sum(x) by (y) limit 3` 限制返回聚合后的 3 条 timeseris，其他的 timeseries 会被丢弃。
+ [histogram_quantile]({{< relref "./functions/transmit.md#histogram_quantile" >}}) 接受第3个参数`boundsLabel`。 这个场景它会返回`lower`和`upper`估计百分位数的界限。具体详情看[这个 issue](https://github.com/prometheus/prometheus/issues/5706).
+ `default` 二元运算. `q1 default q2` 使用`q2`的数据补充`q1`中缺失的部分数据。
+ `if` 二元运算. `q1 if q2` 删掉`q1`中的数据如果数据点在`q2`中不存在。
+ `ifnot` 二元运算. `q1 ifnot q2` 删掉`q1`中的数据，如果数据点在`q2`的结果中存在。
+ `WITH` 模板, 该功能简化编写和维护复杂的查询语句。可以到[WITH templates playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/expand-with-exprs)里试一下.
+ 字符串文本是可以链接的，这在 WITH 模板里很有用，比如：`WITH (commonPrefix="long_metric_prefix_") {__name__=commonPrefix+"suffix1"} / {__name__=commonPrefix+"suffix2"}`.
+ `keep_metric_names`修改器可以应用于[rollup 函数]({{< relref "./functions/rollup.md" >}})和[转换函数transform functions]({{< relref "./functions/transmit.md" >}})。该修改器避免 Metric 名称从结果集中删掉。

## keep_metric_name {#keep_metric_name}

默认情况下，Metric 名称会在应用函数计算后的结果数据中去掉，因为计算后的结果数据改变了原始指标名所代表的含义。这导致当一个函数被应用于多个名称不同的 Timeseries 时，可能会出现`duplicate time series`错误，使用 `keep_metric_names` 可以修复这个错误。

例如 `rate({__name__=~"foo|bar"}) keep_metric_names` 会在返回的数据中保留 `foo` 和 `bar` 指标名。

## 与 PromQL 的差异 {#diff}

### 背景
长期以来，我们无法衡量与PromQL的兼容性。 甚至连一个完整定义的 [PromQL 规范](https://promlabs.com/blog/2020/08/06/comparing-promql-correctness-across-vendors#what-is-correct-in-the-absence-of-a-specification)都没有。 不过后来，[Prometheus Conformance Program](https://prometheus.io/blog/2021/05/03/introducing-prometheus-conformance-program/)发布，目的是认证软件与 Prometheus的兼容性"达到 100% 时，将授予该标志"。 该开源工具 [prometheus/compliance](https://github.com/prometheus/compliance) 就是用来检查兼容性的。 

衡量兼容性的方法很简单--该工具需要一个包含要运行的 [PromQL 查询列表的配置文件](https://github.com/prometheus/compliance/blob/6d63e44ca06d317c879b7406ec24b01a82213aa0/promql/promql-compliance-tester.yml#L107)、一个用作参考的 Prometheus 服务器以及任何其他要测试的软件。 该工具会向 Prometheus 和被测软件发送 PromQL 查询，如果它们的响应不匹配，就会将查询标记为失败。

### 兼容性测试
我们在 Prometheus [v2.30.0](https://github.com/prometheus/prometheus/releases/tag/v2.30.0) 和 VictoriaMetrics [v1.67.0](https://github.com/VictoriaMetrics/VictoriaMetrics/releases/tag/v1.67.0) 之间运行兼容性测试，将得到如下结果：


```plain
====================================================================
General query tweaks:
*  VictoriaMetrics aligns incoming query timestamps to a multiple of the query resolution step.
====================================================================
Total: 385 / 529 (72.78%) passed, 0 unsupported
```

基于上述测试结果，VictoriaMetrics 有 149 个失败用例，和 Prometheus 的兼容性有`72.59%`。让我们来进一步分析下失败的查询用例。

### Keeping metric name

根据 PromQL 的约定， 函数在转换完 metric 数据后，应该[从结果集中丢弃掉 Metric 名称](https://github.com/prometheus/prometheus/issues/380)，因为 Metric 的初试含义已经变了。但是，这种方式有很多弊病。例如，`max_over_time` 函数计算的是 series 里的最大值，但并没有改变它的物理含义。因此, MetricsQL [针对这些函数保留了 metric 名称](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/674)。它也可以用来查询多个 Metric 名称 ，比如：`max_over_time({__name__=~"process_(resident|virtual)_memory_bytes"}[1h])`，这在 PromQL 里会报错 `vector cannot contain metrics with the same labelset`。

因此，测试类型的函数，如`*_over_time`, `ceil` , `floor` , `round` , `clamp_*` , `holt_winters` , `predict_linear` 在 VictoriaMetrics 里都会在结果中故意保留 metric 名称:


```plain
QUERY: avg_over_time(demo_memory_usage_bytes[1s])
-      Metric: s`{instance="demo.promlabs.com:10002", job="demo", type="buffers"}`,
+     Metric: s`demo_memory_usage_bytes{instance="demo.promlabs.com:10002", job="demo", type="buffers"}`,
```

有`92/529(~17%)`个查询测试用例因为在结果中保留 metric 名字而被认为没有对 PromQL 进行兼容。

### 更优的 rate()
凡是涉及对回溯窗口样本值首尾样本值进行计算的 rollup 函数，比如 `rate`、`delta`、`increase` 等函数；其MetricsQL 和 PromQL 都存在统一的计算差异。因此 VictoriaMetrics 使用 `xxx_prometheus` 的命名提供了兼容 Prometheus 统计方式的 rollup 函数，如 `rate_prometheus`、`delta_prometheus`、`increase_prometheus` 等。而默认则使用 MetricsQL 的统计方式。

以 increase 函数为例，MetricsQL 的计算方式更加精准，如下图所示。

假设我们有5个样本值，当回溯窗口大小是`$__interval` 时，我们期望得到的就是`V3-V1`和`V5-V3`两个值。即当前回溯窗口的最后一个样本值应该与前一个回溯窗口的最后一个样本值计算，而不是和本窗口的第一个样本值计算。

![MetricsQL](promql-diff-demo-1.png)

再看 Prometheus 的计算方式，如下图所示。它使用一个回溯窗口的最后一个样本值，与该窗口的第一个值进行计算。因为 V1 样本不在第一个窗口内，V3 不再第二个窗口内，这就导致 Prometheus 计算出来的值是`V3-V2`和`V5-V4`，结果并不正确。

![PromQL](promql-diff-demo-2.png)

此外，Prometheus 的这种统计方式还有另外一个问题。就是如果`$_interval`大小的时间窗口内只有一个样本值，那么`rate`和`increase`这种汇总函数的结果为空。

MetricsQL 在计算`rate`和`increase`时不会应用额外扩展。这解决了整数之间计算得到的小数问题： 

![](promql-diff-demo-3.png)

`increase()`查询在 Prometheus 里会将整数计算扩展而产生小数结果。

在 Prometheus 为`rate`和`increase`选择一个重要的回溯窗口[非常重要](https://www.robustperception.io/what-range-should-i-use-with-rate)。否则，返回结果可能错误或甚至没有数据。[Grafana](https://grafana.com/) 甚至提供了一个特殊的变量[$__rate_interval](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/) 来解决这个问题，但它可能会引起下面的问题：

+ 用户需要在数据源里配置采集间隔，才能使它工作正常；
+ 用户依然需要给每一个用到`rate`的查询语句里手动添加 `$__rate_interval`；
+ 但如果数据源里的数据采集间隔是不一致的，这个方法就不奏效了；或者一个视图里使用了多种数据源。
+ 这只在 Grafana 里支持。

在 MetricsQL 里, 中括号`[]`里的回溯窗口可以省略。 VictoriaMetrics 会基于当前的步长自动设置回溯窗口。例如，`rate(node_network_receive_bytes_total)`和`rate(node_network_receive_bytes_total[$__interval])`是一样的。并且即便这里的`interval`太小导致时间窗口里数据点太少，MetricsQL 会自动扩展它。这就是为什么像`deriv(demo_disk_usage_bytes[1s])`这种查询语句会在 Prometheus 里返回空而在 VictoriaMetrics 会返回数据。

有 39/529(~7%) 个查询 (rate, increase, deriv, changes, irate, idelta, resets 等) 存在这种和 Prometheus 不同的计算逻辑，导致结果不同。

```plain
QUERY: rate(demo_cpu_usage_seconds_total[5m])
-           Value:     Inverse(TranslateFloat64, float64(1.9953032056421414)),
+           Value:     Inverse(TranslateFloat64, float64(1.993400981075324)),
```

关于 MetricsQL 里 rate/increase 更多的内部细节可[查阅文档]({{< relref "./functions/rollup.md#rate" >}}) 和 [Github 上的例子](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1215#issuecomment-850305711).

### NaNs
NaNs 是非法计算结果。 我们来看下 [Prometheus 包含两种 NaNs](https://www.robustperception.io/get-thee-to-a-nannary): [normal NaN](https://github.com/prometheus/prometheus/blob/19152a45d8a8f841206d321f79a60ab6d365a98f/pkg/value/value.go#L22) 和 [stale NaN](https://github.com/prometheus/prometheus/blob/19152a45d8a8f841206d321f79a60ab6d365a98f/pkg/value/value.go#L28)。 Stale NaNs 被用于 "staleness makers" — 一个特殊的值被应用于一个已经 Stale 的。 VictoriaMetrics 不支持这个因为 VictoriaMetrics 需要与许多系统进行整合，不只是 Prometheus，必须有一个方法统一处理 Graphite、InfluxDB、OpenTSDB 和其他数据协议写进来数据的对齐问题。对 Prometheus 的对齐标记也有[支持](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1526)。

Normal NaNs 是算数运算计算出来的结果，比如`0/0=NaN`。但是，在 OpenMetrics 里[没有对 NaNs 的专门描述和用例](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md#nan).

While NaNs are expected when evaluating mathematical expressions, it is not clear how useful they are for users, or if there are any benefits to return NaNs in the result. It looks like the opposite is true because users are [often](https://stackoverflow.com/questions/53430836/prometheus-sum-one-nan-value-result-into-nan-how-to-avoid-it)[confused](https://github.com/prometheus/prometheus/issues/7637)[with](https://github.com/prometheus/prometheus/issues/6780) the [received](https://github.com/prometheus/prometheus/issues/6645)[results](https://stackoverflow.com/questions/47056557/how-to-gracefully-avoid-divide-by-zero-in-prometheus).

MetricsQL consistently deletes NaN from query responses. This behavior is intentional because there is no meaningful way to use such results. That's why testing queries such as `demo_num_cpus * NaN` or `sqrt(-demo_num_cpus)` return an empty response in MetricsQL, and returns NaNs in PromQL.

There were 6 (~1% of 529 tests total) queries in thetest suite expecting NaNs in responses: `sqrt(-metric)` , `ln(-metric)` , `log2(-metric)` , `log10(-metric)` and `metric * NaN` .

### 负 Offset
VictoriaMetrics 支持负 offset，不过 Prometheus 在 [2.26](https://github.com/prometheus/prometheus/releases/tag/v2.26.0) 版本之后也开始支持了（通过命令行参数开启）。但是，Prometheus 的查询结果还是和 VictoriaMetrics 不一样。

![](promql-diff-demo-4.png)

VictoriaMetrics 和 Prometheus 的负 offset 查询结果。VictoriaMetrics查询结果偏移`1e7`，以直观地显示线条之间的差异。没有这个偏移，除了最后5分钟外，它们是相同的。

这种逻辑不是我们期望的，更多的详情可以参考下面的讨论：

[Series with negative offset are continued with the last value up to 5min · Discussion #9428 ·…You can't perform that action at this time. You signed in with another tab or window. You signed out in another tab or…github.com](https://github.com/prometheus/prometheus/discussions/9428)

VictoriaMetrics 并不计划改变负 offset 的逻辑，因为这个特性已经被发布[2年了](https://github.com/prometheus/prometheus/issues/6282#issuecomment-564301756)，Prometheus 是后做的。

有 3/529(~0.5%) 个查询测试用例是针对`-1m`,`-5m`,`-10m`偏移的：

```plain
QUERY: demo_memory_usage_bytes offset -1m
RESULT: FAILED: Query succeeded, but should have failed.
```

### 精度下降
VictoriaMetrics 在下面的测试用例会失败：

```plain
QUERY: demo_memory_usage_bytes % 1.2345
  Timestamp: s"1633073960",
- Value: Inverse(TranslateFloat64, float64(0.038788650870683394)),
+ Value: Inverse(TranslateFloat64, float64(0.038790081382158004)),
```

结果确实不同。它在小数点后的第5个数字上开始出现差别，原因不在MetricsQL中，而是在VictoriaMetrics本身中。查询结果不正确，因为指标的原始数据点值在Prometheus和VictoriaMetrics之间不匹配：

```plain
curl  --data-urlencode 'query=demo_memory_usage_bytes{instance="demo.promlabs.com:10000", type="buffers"}' --data-urlencode 'time=1633504838' 
..."value":[1633504838,"148164507.40843752"]}]}}%                                                                                  curl  --data-urlencode 'query=demo_memory_usage_bytes{instance="demo.promlabs.com:10000", type="buffers"}' --data-urlencode 'time=1633504838'
..."value":[1633504838,"148164507.4084375"]}]}}%
```

VictoriaMetrics may reduce the precision of values with more than 15 decimal digits due to the [used compression algorithm](https://faun.pub/victoriametrics-achieving-better-compression-for-time-series-data-than-gorilla-317bc1f95932). If you want to get more details about how and why this happens, please read the "Precision loss" section in [Evaluating Performance and Correctness](https://medium.com/@valyala/evaluating-performance-and-correctness-victoriametrics-response-e27315627e87). In fact, any solution that works with floating point values has precision loss issues because of the nature of [floating-point arithmetic](https://en.wikipedia.org/wiki/Floating-point_arithmetic).

While such precision loss may be important in rare cases, it doesn't matter in most practical cases because the [measurement error](https://en.wikipedia.org/wiki/Observational_error) is usually much larger than the precision loss.

While VictoriaMetrics does have higher precision loss than Prometheus, we believe it is completely justified by the [compression gains](https://valyala.medium.com/prometheus-vs-victoriametrics-benchmark-on-node-exporter-metrics-4ca29c75590f) our solution generates. Moreover, only 3 (~0.5% of 529 tests total) queries from the test suite fail due to precision loss.

### Query succeeded, but should have failed
The following query fails for PromQL but works in MetricsQL:


```plain
QUERY: {__name__=~".*"}
RESULT: FAILED: Query succeeded, but should have failed.
```

PromQL rejects such a query to prevent database overload because query [selects all the metrics](https://github.com/prometheus/prometheus/issues/2162) from it. At the same time, PromQL does not prevent a user from running an almost identical query`{__name__=~".+"}` , which serves the same purpose.

The other example of a failing query is the following:


```plain
QUERY: label_replace(demo_num_cpus, "~invalid", "", "src", "(.*)")
RESULT: FAILED: Query succeeded, but should have failed.
```

The query fails for PromQL because it doesn't allow using `~` char in label names. VictoriaMetrics accepts data ingestion from various protocols and systems where such char is allowed, so it [has to support](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/672#issuecomment-670189308) a wider list of allowed chars.

There were 2 (~0.3% of 529 tests total) queries that failed because of incompatibility but we can’t imagine a situation where it would harm a user’s experience.

### Summary
There are differences between MetricsQL and PromQL. MetricsQL was created long after the PromQL with the goal of improving the user experience and making the language easier to use and understand.

How compatibility is measured in the [Prometheus Conformance Program](https://prometheus.io/blog/2021/05/03/introducing-prometheus-conformance-program/) isn't ideal because it really only shows if the tested software uses Prometheus PromQL library under the hood or not. This is particularly complicated for solutions written in programming languages other than Go.

By the way, the percentage of failing tests is easy to increase or decrease by changing the number of range intervals (e.g. 1m, 5m etc.) in tests. In the case of VictoriaMetrics, about 90 tests have failed not because of wrong calculations, but because of the metric name present in the response. Of course, there is no ideal way to be fair to everyone. That's why this post exists to explain the differences.

We also want to say a big thank you to [Julius Volz](https://github.com/juliusv), the author of these [compliance tests](https://promlabs.com/promql-compliance-tests/). Thanks to his work and patience we were able to fix most of the real incompatibility issues in MetricsQL.


## 子查询 {#subquery}