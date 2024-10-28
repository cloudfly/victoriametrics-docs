---
title: MetricQL
date: 2024-10-28T14:35:37+08:00
description: 介绍 MetricQL 的一些关键特性，以及它和 PromQL 的主要区别
keyworlds:
- or
- metricsql
- graphite 过滤器
- WITH
- 语法
- subquery
weight: 1
---

VictoriaMetrics 提供了一种特殊的查询语言，用于执行查询语句 - MetricsQL。它是一个类似 [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics) 的查询语言，具有强大的函数和功能集，专门用于处理时间序列数据。MetricsQL 完全兼容 PromQL，因此他们之间大部分概念都是一样的。

所以，使用 VictoriaMetrics 替换 Prometheus 后，由 Prometheus 数据源创建的 Grafana 监控面板不会受到任何影响。然而，这两种语言之间也是存在[一定的差异](#diff)的。

有一个[独立的 MetricQL 库](https://godoc.org/github.com/VictoriaMetrics/metricsql)可用于在其他应用中解析 MetricQL 语句。

如果你对 PromQL 不熟，建议先阅读一下[这篇文章]({{< relref "promql.md" >}})。

## MetricQL 功能特性
MetricsQL 除了实现了 PromQL 的所有功能，还额外增加了下面的特性，这些特性目的是解决实际应用场景中遇到的问题。如果你认为 MetricsQL 中缺失一些有用的功能，可以[提交一个 Feature Request](https://github.com/VictoriaMetrics/VictoriaMetrics/issues)

这些特性可以在 [VictoriaMetrics playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/) 进行验证，也可以在你自己的 [VictoriaMetrics 实例]({{< relref "quickstart.md" >}})上验证。


### 兼容 Graphite 的过滤器 {#graphite-filter}

支持兼容 Graphite 过滤器的写法，比如`{__graphite__="foo.*.bar"}`。VictoriaMetrics 支持使用`__graphite__`伪 Label 在 VictoriaMetrics 中使用兼容 Graphite 的过滤器查询时序数据。  
比如，`{__graphite__="foo.*.bar"}`等同于`{__name__=~"foo[.][^.]*[.]bar"}`，但它的性能更高并且易用。更多内容请阅读 [Graphite 模糊匹配](https://graphite.readthedocs.io/en/latest/render_api.html#paths-and-wildcards)。因此可在 Grafana 中 VictoriaMetrics 可以作为 Graphite 数据源。

[`label_graphite_group`]()可用于从 Graphite 指标名中解析出分组。

`__graphite__`伪 Label 支持正则过滤，比如`(value1|...|valueN)`。他们会被转换成在 Graphite 中使用的`{value1,...,valueN}`语法。这个能力允许在 Grafana 模板变量中使用多值传递给`__graphite__`。  
例如，Grafana 将`{__graphite__=~"foo.($bar).baz"}`扩展成了`{__graphite__=~"foo.(x|y).baz"}`，如果`$bar`模板变量中包含`x`和`y`两个值。在这个例子中，语句会被在执行前自动被转换成`{__graphite__=~"foo.{x,y}.baz"}`。

### 可省略回溯窗口

中括号`[]`中的回溯窗口可以被省略。VictoriaMetrics 会基于原始样本间隔和请求参数自动设置回溯窗口（比如传递到[`/api/v1/query_range`]({{< relref "../../quickstart.md#range-query" >}})中的`step`参数)。

例如，`rate(node_network_receive_bytes_total)`在 VictoriaMetrics 中是合法的，在使用 Grafana 时，它等同于`rate(node_network_receive_bytes_total[$__interval])`。


中括号`[]`内的回溯窗口可以是小数。比如，`rate(node_network_receive_bytes_total[1.5m] offset 0.5d)`。

### `or`关键字

[Series 选择器]({{< relref "./basic.md#filter" >}}) 接收多个`or`过滤器。比如，`{env="prod",job="a" or env="dev",job="b"}`表示使用`{env="prod",job="a"}`或`{env="dev",job="b"}`过滤 Series. 更多详情看[这些文档]({{< relref "./basic.md#or-filter" >}})。


### 多语句聚合
[聚合函数]({{< relref "./functions/aggregation.md" >}}) 接收多个参数。例如，`avg(q1, q2, q3)`会将`q1`,`q2`和`q3`返回的所有 Timeseries 数据点计算平均值。

### `@`修改器
[@ 修改器]({{< relref "./basic.md#modifier" >}}) 可以放在语句中的任何地方。例如，`sum(foo) @ end()`在`[start ... end]`查询的数据中，`end`时间点上的数据计算`sum(foo)`。

时间计算子达式可以应用在 [@ 修改器]({{< relref "./basic.md#modifier" >}}) 上，比如，`foo @ (end() - 1h)`在`[start ... end]`查询的数据中，`end -1 hour`时间点上的数据计算`sum(foo)`。

### offset 
[offset]({{< relref "./basic.md#offset-modifier" >}})，中括号`[]`中的回溯窗口和[子查询](#subquery)里的`step`值会引用当前的步长，该步长会通过 Grafana 的`$__interaval`和`[Ni]`语法传递。例如，`rate(metric[10i] offset 5i)`会返回前 10 个步长时间内每秒增长量，时间偏移 5 个步长。

[offset]({{< relref "./basic.md#offset-modifier" >}}) 可以放在语句的任何地方。比如`sum(foo) offset 24h`，表示对24小时之前的`foo`指标算总和。

[offset]({{< relref "./basic.md#offset-modifier" >}}) 可以是小数。比如，`rate(node_network_receive_bytes_total[1.5m] offset 0.5d)`，表示获取半天前的机器流量，流量统计窗口是当时的一分半钟。

### 数字单位

时间段表达式后缀是可以省略的，默认单位是**秒**，比如，`rate(m[300] offset 1800)`等同于`rate(m[5m]) offset 30m`。

时间段可以在语句的任何地方使用。比如，`sum_over_time(m[1h]) / 1h`等同于`sum_over_time(m[1h]) / 3600`。

数字类型值可以使用`K`, `Ki`, `M`, `Mi`, `G`, `Gi`, `T`和`Ti`后缀。例如，`8K`等同于`8000`, `1.2Mi`等同于`1.2*1024*1024`.

### 语法容错

所有的列表中最后的的逗号`,`字符是可接受的，比如在 Label 过滤器，函数参数，以及`WITH`模板表达式中。这回简化查询语句的自动生成。

例如，这些从查询都是允许的：`m{foo="bar",}`, `f(a, b,)`, `WITH (x=y,) x`。

### WITH 模板

`WITH`模板, 该功能简化编写和维护复杂的查询语句。可以到[WITH templates playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/expand-with-exprs)里试一下.

字符串文本是可以链接的，这在 WITH 模板里很有用，比如：`WITH (commonPrefix="long_metric_prefix_") {__name__=commonPrefix+"suffix1"} / {__name__=commonPrefix+"suffix2"}`.

### 支持更丰富字符集
Metric 名和 Label 名允许使用 unicode 字符。例如`температура{город="Киев"}`也是合法的。  
Metric 名和 Label 名允许包含转义字符。比如`foo\-bar{baz\=aa="b"}`是合法的表达式。 它返回的 Timeseries 指标名为`foot-bar`，包含一个 Label，其名是`baz=aa`，值为`b`，此外，下面的转义也是支持的：
- `\xXX`, 这里`XX`代表 ascii 码表示的字符。
- `\uXXXX`, 这里`XXXX`是用 unicode 编码表示的字符。

### Limit

聚合函数支持使用`limit N`后缀， 其目的是限制输出的 series 数量。例如，`sum(x) by (y) limit 3`限制返回聚合后的 3 条 timeseris，其他的 timeseries 会被丢弃。

### 二元运算

+ `default`二元运算. `q1 default q2`使用`q2`的数据补充`q1`中缺失的部分数据。
+ `if`二元运算. `q1 if q2`删掉`q1`中的数据如果数据点在`q2`中不存在。
+ `ifnot`二元运算. `q1 ifnot q2`删掉`q1`中的数据，如果数据点在`q2`的结果中存在。


### keep_metric_name

默认情况下，Metric 名称会在应用函数计算后的结果数据中去掉，因为计算后的结果数据改变了原始指标名所代表的含义。  
这导致当一个函数被应用于多个名称不同的 Timeseries 时，可能会出现`duplicate time series`错误，使用[`keep_metric_names`](#keep_metric_name)可以修复这个错误，它能避免 Metric 名称从结果集中删掉。

例如`rate({__name__=~"foo|bar"}) keep_metric_names`会在返回的数据中保留`foo`和`bar`指标名。

`keep_metric_names`修改器可以应用于[rollup 函数]({{< relref "./functions/rollup.md" >}})和[转换函数transform functions]({{< relref "./functions/transmit.md" >}})。

## 与 PromQL 的差异 {#diff}

MetricsQL 在以下功能上与 PromQL 实现方式不同，这些差异改进了用户体验：

1. MetricsQL在计算范围函数（如`rate`和`increase`）时，考虑了方括号中回溯窗口之前的上一个点。这样可以返回用户对于`increase(metric[$__interval])`查询所期望的更精确结果，而不是像 Prometheus 为此类查询返回的结果并不完整，[下文有详细解释](#better-rate)。 
2. MetricsQL 不会推测范围函数的结果。这解决了 [Prometheus 中存在的问题](https://github.com/prometheus/prometheus/issues/3746)。有关 VictoriaMetrics 和 Prometheus 计算`rate`和`increase`的技术细节，请参阅 [issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1215#issuecomment-850305711)。 
3. MetricsQL对于中括号`[]`中回溯窗口(即 step 或 interval)小于抓取间隔的`rate`查询返回符合预期的非空结果。这解决了 [Grafana 中存在的问题](https://github.com/grafana/grafana/issues/11451)。还请参阅[这篇文章](https://www.percona.com/blog/2020/02/28/better-prometheus-rate-function-with-victoriametrics/)。
4. MetricsQL将`scalar`类型与没有 Label 的`instant vector`视为相同，因为这些类型之间微小差异通常会让用户感到困惑。有关详细信息，请参阅[相应的 Prometheus 文档](https://prometheus.io/docs/prometheus/latest/querying/basics/#expression-language-data-types)。 
5. MetricsQL从查询结果中删除所有`NaN`值，因此一些查询（例如`(-1)^0.5`）在 VictoriaMetrics 中返回空结果，但在 Prometheus 中则返回一系列`NaN`值。  
请注意，Grafana 不会为 NaN 值绘制任何线条或点，因此最终在页面上看到的结果，VictoriaMetrics 和 Prometheus 上看起来是相同的。 
6. 在应用一些函数后，MetricsQL 保留指标名称，并且该函数不改变原始时间序列的含义。例如，`min_over_time(foo)`或`round(foo)`将在结果中保留`foo`指标名称。有关详细信息，请参阅[issue](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/674)。

下面我们将会对上面所说的不同进行详细论述。

### 背景
长期以来，我们无法衡量与 PromQL 的兼容性。甚至连一个完整定义的 [PromQL 规范](https://promlabs.com/blog/2020/08/06/comparing-promql-correctness-across-vendors#what-is-correct-in-the-absence-of-a-specification)都没有。 不过后来，[Prometheus Conformance Program](https://prometheus.io/blog/2021/05/03/introducing-prometheus-conformance-program/)发布，目的是测试一个软件与 Prometheus 的兼容性"达到 100% 时，将授予该标志"。开源工具 [prometheus/compliance](https://github.com/prometheus/compliance) 就是用来检查兼容性的。 

衡量兼容性的方法很简单，该工具需要一个包含要运行的 [PromQL 查询列表的配置文件](https://github.com/prometheus/compliance/blob/6d63e44ca06d317c879b7406ec24b01a82213aa0/promql/promql-compliance-tester.yml#L107)，和一个用作参考的 Prometheus 服务器以及任何其他要测试的软件。 该工具会向 Prometheus 和被测软件发送 PromQL 查询，如果它们的返回的数据不匹配，就会将查询测试用例标记为失败。

### 兼容性测试
我们在 Prometheus [v2.30.0](https://github.com/prometheus/prometheus/releases/tag/v2.30.0) 和 VictoriaMetrics [v1.67.0](https://github.com/VictoriaMetrics/VictoriaMetrics/releases/tag/v1.67.0) 之间运行兼容性测试，将得到如下结果：


```plain
====================================================================
General query tweaks:
*  VictoriaMetrics aligns incoming query timestamps to a multiple of the query resolution step.
====================================================================
Total: 385 / 529 (72.78%) passed, 0 unsupported
```

如上测试结果所示，VictoriaMetrics 有`149`个失败用例，和 Prometheus 的兼容性有`72.59%`。让我们来进一步分析下失败的查询用例。

### Keeping metric name {#keep_metric_name}

根据 PromQL 的约定，函数在转换完 metric 数据后，应该[从结果集中丢弃掉 Metric 名称](https://github.com/prometheus/prometheus/issues/380)，因为 Metric 的初试含义已经变了。

但是，这种方式有很多弊病。例如，`max_over_time`函数计算的是 series 里的最大值，但并没有改变它的物理含义。因此，MetricsQL [针对这些函数保留了 metric 名称](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/674)。  
它也可以用来查询多个 Metric 名称 ，比如：`max_over_time({__name__=~"process_(resident|virtual)_memory_bytes"}[1h])`，但这在 PromQL 里会报错:`vector cannot contain metrics with the same labelset`。

因此，测试类型的函数，如`*_over_time`, `ceil`, `floor`, `round`, `clamp_*`, `holt_winters`, `predict_linear`在 VictoriaMetrics 里都会在结果中故意保留 metric 名称:

```plain
QUERY: avg_over_time(demo_memory_usage_bytes[1s])
-      Metric: s`{instance="demo.promlabs.com:10002", job="demo", type="buffers"}`,
+     Metric: s`demo_memory_usage_bytes{instance="demo.promlabs.com:10002", job="demo", type="buffers"}`,
```

有`92/529(约17%)`个查询测试用例因为在结果中保留 metric 名字而被认为没有对 PromQL 进行兼容。

### 更优的 rate() {#better-rate}
凡是涉及对回溯窗口样本值首尾样本值进行计算的[rollup 函数]({{< relref "./functions/rollup.md" >}})，比如`rate`、`delta`、`increase`等函数；其 MetricsQL 和 PromQL 都存在统一的计算差异。因此 VictoriaMetrics 使用`xxx_prometheus`的命名提供了兼容 Prometheus 统计方式的 rollup 函数，如`rate_prometheus`、`delta_prometheus`、`increase_prometheus`等。而默认则使用 MetricsQL 的统计方式。

以`increase`函数为例，MetricsQL 的计算方式更加精准，如下图所示。

假设我们有5个样本值，当回溯窗口大小是`$__interval`时，我们期望得到的就是`V3-V1`和`V5-V3`两个值。即当前回溯窗口的最后一个样本值应该与前一个回溯窗口的最后一个样本值计算，而不是和本窗口的第一个样本值计算。

![MetricsQL](promql-diff-demo-1.png)

再看 Prometheus 的计算方式，如下图所示。它使用一个回溯窗口的最后一个样本值，与该窗口的第一个值进行计算。因为`V1`样本不在第一个窗口内，`V3`不再第二个窗口内，这就导致 Prometheus 计算出来的值是`V3-V2`和`V5-V4`，结果并不正确。

![PromQL](promql-diff-demo-2.png)

此外，Prometheus 的这种统计方式还有另外一个问题。就是如果`$_interval`大小的时间窗口内只有一个样本值，那么`rate`和`increase`这种汇总函数的结果为空。

MetricsQL 在计算`rate`和`increase`时不会应用额外扩展。这解决了整数之间计算得到的小数问题： 

![](promql-diff-demo-3.png)

`increase()`查询在 Prometheus 里会将整数计算扩展而产生小数结果。

在 Prometheus 为`rate`和`increase`选择一个合适的回溯窗口[非常重要](https://www.robustperception.io/what-range-should-i-use-with-rate)。否则，返回结果可能错误或甚至没有数据。[Grafana](https://grafana.com/) 甚至提供了一个特殊的变量[$__rate_interval](https://grafana.com/blog/2020/09/28/new-in-grafana-7.2-__rate_interval-for-prometheus-rate-queries-that-just-work/) 来解决这个问题，但它还是带来以下问题：

1. 用户需要在数据源里配置采集间隔，才能使它工作正常；
1. 用户依然需要给每一个用到`rate`的查询语句里手动添加`$__rate_interval`；
1. 但如果数据源里的数据采集间隔是不一致的，这个方法就不奏效了；或者一个视图里使用了多种数据源。
1. 这只在 Grafana 里支持。

在 MetricsQL 里, 中括号`[]`里的回溯窗口可以省略。 VictoriaMetrics 会基于当前的步长自动设置回溯窗口。例如，`rate(node_network_receive_bytes_total)`和`rate(node_network_receive_bytes_total[$__interval])`是一样的。并且即便这里的`interval`太小导致时间窗口里数据点太少，MetricsQL 会自动扩展它。
这就是为什么像`deriv(demo_disk_usage_bytes[1s])`这种查询语句会在 Prometheus 里返回空而在 VictoriaMetrics 会返回数据。

有`39/529(约7%)`个查询(`rate`,`increase`,`deriv`,`changes`,`irate`,`idelta`,`resets`等) 存在这种和 Prometheus 不同的计算逻辑，导致结果不同。

```plain
QUERY: rate(demo_cpu_usage_seconds_total[5m])
-           Value:     Inverse(TranslateFloat64, float64(1.9953032056421414)),
+           Value:     Inverse(TranslateFloat64, float64(1.993400981075324)),
```

关于 MetricsQL 里`rate/increase`更多的内部细节可[查阅文档]({{< relref "./functions/rollup.md#rate" >}})或 [Github 上的例子](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1215#issuecomment-850305711).

### NaNs
NaNs 是非法计算结果。 我们来看下 [Prometheus 包含两种 NaNs](https://www.robustperception.io/get-thee-to-a-nannary): 
- [Normal NaN](https://github.com/prometheus/prometheus/blob/19152a45d8a8f841206d321f79a60ab6d365a98f/pkg/value/value.go#L22)
- [Stale NaN](https://github.com/prometheus/prometheus/blob/19152a45d8a8f841206d321f79a60ab6d365a98f/pkg/value/value.go#L28)

Stale NaNs 被用于 "staleness makers"(坏点标记)，即标记处某一个时间的数据点不能用。

VictoriaMetrics 不支持这个，因为 VictoriaMetrics 需要与许多系统进行整合，不只是 Prometheus；必须有一个方法统一处理来自 Graphite、InfluxDB、OpenTSDB 和其他数据协议写进来数据的坏点问题。对 Prometheus 的坏点标记也有[支持](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/1526)。

Normal NaNs 是算数运算计算出来的结果，比如`0/0=NaN`。但是，在 OpenMetrics 里[没有对 NaNs 的专门描述和用例](https://github.com/OpenObservability/OpenMetrics/blob/main/specification/OpenMetrics.md#nan).

虽然在评估数学表达式时预期会出现`NaN`，但尚不清楚它们对用户有多大用处，或者在结果中返回`NaN`是否有任何好处。目前看来不仅没好处，还让用户[经常](https://stackoverflow.com/questions/53430836/prometheus-sum-one-nan-value-result-into-nan-how-to-avoid-it)[对](https://github.com/prometheus/prometheus/issues/6780)[收到](https://github.com/prometheus/prometheus/issues/6645)的[结果](https://stackoverflow.com/questions/47056557/how-to-gracefully-avoid-divide-by-zero-in-prometheus)感到[困惑](https://github.com/prometheus/prometheus/issues/7637)。

MetricsQL 一贯地从查询响应中删除`NaN`。这种逻辑是故意的，因为我们认为`NaN`数据没有意义。这就是为什么在 MetricsQL 中测试诸如`demo_num_cpus * NaN`或`sqrt(-demo_num_cpus)`的查询会返回空结果，而在 PromQL 中则返回`NaN`。

有`6/529(约1%)`个测试用例在结果中期待返回 NaN：`sqrt(-metric)`, `ln(-metric)`, `log2(-metric)`, `log10(-metric)`and `metric * NaN`。

### 负 Offset
VictoriaMetrics 支持负 offset，不过 Prometheus 在 [2.26](https://github.com/prometheus/prometheus/releases/tag/v2.26.0) 版本之后也开始支持了（通过启动参数开启）。但是，Prometheus 的处理方式还是和 VictoriaMetrics 不太一样。

![](promql-diff-demo-4.png)

上图是 VictoriaMetrics 和 Prometheus 的负 offset 查询结果。(我们让VictoriaMetrics查询结果偏移了`1e7`，以直观地显示线条之间的差异）

这种逻辑不是我们期望的，更多的详情可以参考下面的讨论：

[Series with negative offset are continued with the last value up to 5min · Discussion #9428 ·…You can't perform that action at this time. You signed in with another tab or window. You signed out in another tab or…github.com](https://github.com/prometheus/prometheus/discussions/9428)

VictoriaMetrics 并不计划改变负 offset 的逻辑，因为这个特性已经被发布[2年了](https://github.com/prometheus/prometheus/issues/6282#issuecomment-564301756)，Prometheus 是后做的。

有`3/529(约0.5%)`个查询测试用例是针对`-1m`,`-5m`,`-10m`偏移的：

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

结果确实不同。它在小数点后的第 5 个数字上开始出现差别，原因不出在 MetricsQL 中，而是在 VictoriaMetrics 本身中。查询结果不正确，是因为指标的原始数据点值在 Prometheus 和 VictoriaMetrics 之间不匹配：

```plain
curl  --data-urlencode 'query=demo_memory_usage_bytes{instance="demo.promlabs.com:10000", type="buffers"}' --data-urlencode 'time=1633504838' 
..."value":[1633504838,"148164507.40843752"]}]}}%                                                                                  curl  --data-urlencode 'query=demo_memory_usage_bytes{instance="demo.promlabs.com:10000", type="buffers"}' --data-urlencode 'time=1633504838'
..."value":[1633504838,"148164507.4084375"]}]}}%
```

由于使用的[压缩算法](https://faun.pub/victoriametrics-achieving-better-compression-for-time-series-data-than-gorilla-317bc1f95932)的不同，VictoriaMetrics 可能会降低超过`15`位小数的数据精度。如果您想了解更多关于这种情况发生的原因和方式，请阅读[《评估性能和正确性》](https://medium.com/@valyala/evaluating-performance-and-correctness-victoriametrics-response-e27315627e87)中的**精度损失**部分。
事实上，任何处理浮点值的解决方案都会因为[浮点运算的性质](https://en.wikipedia.org/wiki/Floating-point_arithmetic)而存在精度损失问题。

虽然这种精度损失在极少数情况下可能影响比较大，但在大多数实际情况下并不重要，因为[测量误差](https://en.wikipedia.org/wiki/Observational_error)通常比精度损失大得多。

虽然 VictoriaMetrics 的精度损失比 Prometheus 更高，但我们相信这种损失完全可以通过我们的解决方案所产生的[压缩收益](https://valyala.medium.com/prometheus-vs-victoriametrics-benchmark-on-node-exporter-metrics-4ca29c75590f)来证明其合理性。此外，测试套件中的 529 个查询中只有 3 个（约占 0.5%）因精度损失而失败。

### 非预期查询成功
下面的语句在 PromQL 里会报错，但在 MetricsQL 里会正常运行：

```plain
QUERY: {__name__=~".*"}
RESULT: FAILED: Query succeeded, but should have failed.
```

PromQL 拒绝此类查询以防止数据库过载，因为查询选择了[所有指标](https://github.com/prometheus/prometheus/issues/2162)。但是，PromQL 不会阻止用户运行几乎相同的查询`{__name__=~".+"}`，这俩语句其实没太大区别。

### 其他失败

```plain
QUERY: label_replace(demo_num_cpus, "~invalid", "", "src", "(.*)")
RESULT: FAILED: Query succeeded, but should have failed.
```

查询在 PromQL 中失败，因为它不允许在 Label Name 中使用`~`字符。VictoriaMetrics 接受来自各种协议和系统的数据写入，这些协议和系统允许使用此类字符，因此它必须[支持](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/672#issuecomment-670189308)更广泛的合法字符列表。

在 529 个测试中，有 2 个（约占 0.3%）查询因不兼容而失败，但我们无法想象这种情况会对用户体验造成影响。

### 总结

MetricsQL 和 PromQL 之间存在差异。MetricsQL 是在 PromQL 之后很久才创建的，目的是改善用户体验，使语言更易于使用和理解。

[Prometheus 合规性计划](https://prometheus.io/blog/2021/05/03/introducing-prometheus-conformance-program/)中衡量兼容性的方式并不理想，因为它实际上只是显示被测试的软件是否在底层使用了 Prometheus PromQL 库。这对于用 Go 语言以外的编程语言编写的解决方案来说尤其复杂。

顺便说一下，通过更改测试中的范围间隔（例如`1m`、`5m`等），很容易增加或减少失败测试的百分比。在 VictoriaMetrics 的情况下，大约有 90 个测试失败并不是因为计算错误，而是因为查询结果中存在的指标名称。当然，没有一种理想的方式可以对所有人都公平。这就是这篇文章存在的意义，目的是解释这些差异。

我们还要特别感谢这些[合规性测试](https://promlabs.com/promql-compliance-tests/)的作者 [Julius Volz](https://github.com/juliusv) 。感谢他的工作和耐心，我们能够修复 MetricsQL 中大多数真正的不兼容问题。


## 子查询 {#subquery}

MetricsQL 支持并扩展了 PromQL 子查询。详情请参见[这篇文章](https://valyala.medium.com/prometheus-subqueries-in-victoriametrics-9b1492b720b3)。任何针对非[series selector]({{< relref "./basic.md#filter" >}})的 [rollup 函数]({{< relref "./functions/rollup.md" >}})都会形成一个子查询。由于隐式查询转换，嵌套的 rollup 函数可以是隐式的。例如，`delta(sum(m))`会被隐式转换为`delta(sum(default_rollup(m))[1i:1i])`，因此它变成了一个子查询，因为它包含了嵌套在`delta`中的`default_rollup`。从 v1.101.0 版本开始，可以通过`-search.disableImplicitConversion`和`-search.logImplicitConversion`启动参数禁用或记录此行为。

VictoriaMetrics 按照下面的逻辑执行子查询：
1. 它使用外部 rollup 函数的 step 值来计算内部 rollup 函数。例如，对于表达式`max_over_time(rate(http_requests_total[5m])[1h:30s])`，内部函数`rate(http_requests_total[5m])`是以`step=30s`计算的。生成的数据点按`step`对齐。
2. 它使用 Grafana 传递给`/api/v1/query_range`的 step 值，在内部`rollup`函数的结果上计算外部 rollup 函数。

## 隐式转换 {#conversion}

VictoriaMetrics 在开始计算之前，对传入的查询执行以下隐式转换。

- 如果方括号`[]`中的回溯窗口在内部 [rollup 函数]({{< relref "./functions/rollup.md" >}})中缺失，则会自动设置为以下值：
  - 对于传递给`/api/v1/query_range`或`/api/v1/query`的`step`值，所有 [rollup 函数]({{< relref "./functions/rollup.md" >}})（除了`default_rollup`和`rate`）都会使用该值。这个值在 Grafana 中被称为`$__interval`，在 MetricsQL 中被称为`1i`。例如，`avg_over_time(temperature)`会自动转换为`avg_over_time(temperature[1i])`。
  - 对于`max(step, scrape_interval)`，其中`scrape_interval`是`default_rollup`和`rate`函数的原始样本间隔。这可以避免当`step`小于`scrape_interval`时图表上出现意外的间隙。
- 没有使用 rollup 函数内的所有过滤器，都会被自动放到`default_rollup`函数里。比如：
  - `foo`被转换成`default_rollup(foo)`
  - `foo + bar`被转换成`default_rollup(foo) + default_rollup(bar)`
  - `count(up)`被转换成`count(default_rollup(up))`，因为`count`不是一个 rollup 函数，而是一个[聚合函数]({{< relref "./functions/aggregation.md" >}})
  - `abs(temperature)`被转换成`abs(default_rollup(temperature))`, 因为`abs`不是一个 rollup 函数，而是一个[转换函数]({{< relref "./functions/transmit.md" >}})
- 如果子查询语句中的中括号`[]`内的窗口被省略了，则默认会使用`1i`。 比如，`avg_over_time(rate(http_requests_total[5m])[1h])`被自动转换成`avg_over_time(rate(http_requests_total[5m])[1h:1i])`.
- 如果非指标过滤器的什么东西传递给了 rollup 函数，那么子查询会自动使用`1i`作为回溯窗口，比如，`rate(sum(up))`被自动转换成 `rate((sum(default_rollup(up)))[1i:1i])`。改逻辑可以用启动参数`-search.disableImplicitConversion`and `-search.logImplicitConversion` 禁用掉，该参数在在 v1.101.0 发布的。