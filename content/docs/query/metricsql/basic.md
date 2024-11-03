---
title: 基本用法
date: 2024-11-03T19:37:20+08:00
description: 介绍 MetricQL 的一些基本用法，用一些简单的样例由浅入深
weight: 1
---

## 过滤器 {#filter}

{{% include "snippets/metricsql-filter.md" %}}

### 使用名字过滤 {#filter-by-name}
有时我们可能需要同时返回多个监控指标。就如同[数据模型]({{< relref "../../concepts.md#metrics" >}})中提到的，Metric 名称本质上也是一个普通的 Label 的值，其 Label 名是`__name__`。所以可以通过对 Metric 名使用正则的方式，来过滤出多个指标的数据：

```
{__name__=~"requests_(error|success)_total"}
```

上面的查询语句会返回 2 个 Metric 的 Timeseries：`requests_error_total`和`requests_success_total`.

### 利用 or 使用多个过滤器 {#or-filter}
[MetricsQL]({{< relref "./_index.md" >}}) 支持查询至少满足多个过滤器中的一个方式来获取 Timeseries。这些过滤器必须在花括号内使用`or`分割。 比如，下面的查询代表查询 Label 满足`{job="app1",env="prod"}`或`{job="app2",env="dev"}`的 Timeseries：

```
{job="app1",env="prod" or job="app2",env="dev"}
```

过滤器的个数是没有限制的。这个功能可以对查询到的 series 直接运用 [rollup 函数]({{< relref "./functions/rollup.md" >}})（比如 [rate]({{< relref "./functions/rollup.md#rate" >}})），这样就不需要使用[子查询]({{< relref "./_index.md#subquery" >}})了：

```
rate({job="app1",env="prod" or job="app2",env="dev"}[5m])
```

如果你需要对同一 Label 使用多个过滤器来查询 Timeseries，从性能角度来看，最好使用正则表达式`{label=~"value1|...|valueN"}`而不是使用`{label="value1" or ... or label="valueN"}`。

## 算数运算 {#math}
MetricsQL 支持所有基本的算数运算：

+ 加法 - `+`
+ 减法 - `-`
+ 乘法 - `*`
+ 除法 - `/`
+ 取模 - `%`
+ 指数 - `^`

我们可以在多个指标之间进行各种计算。比如，下面的查询语句就是计算错误请求率：

```
(requests_error_total / (requests_error_total + requests_success_total)) * 100
```

### 合并多个 Timeseries
要使用算术运算合并多个 Timeseries ，我们需要了解匹配规则。否则，查询会出错或给出错误的结果。匹配规则的逻辑很简单：

+ MetricsQL引擎在不影响 Label 的情况下，从算术操作左右两侧的所有 Timeseries 中**去除指标名称**。
+ 对于左侧的每个 Timeseries，MetricsQL 引擎会在右侧搜索具有相同 Label Set 的 Timeseries，对每个数据点执行运算操作，并返回具有相同 Label Set 的结果时间序列。**如果没有匹配项，则结果时间序列将从结果中删除。**
+ 匹配规则可以通过`ignore`、`on`、`group_left`和`group_right`运算符进行扩展。详细信息请参阅[这些文档](https://prometheus.io/docs/prometheus/latest/querying/operators/#vector-matching)。

## 比较运算
MetricsQL 支持下面这些比较运算符：

+ 等于 - `==`
+ 不等于 - `!=`
+ 大于 - `>`
+ 大于等于 - `>=`
+ 小于 - `<`
+ 小于等于 - `<=`

这些运算符可以像算术运算符一样应用于任意的 MetricsQL 表达式。比较运算的结果是只包含 value 匹配成功的的 Timeseries。例如，下面的查询将仅返回内存使用超过`100MB`的进程列表。

```plsql
process_resident_memory_bytes > 100*1024*1024
```

## 聚合与分组函数
MetricsQL 支持对 Timeseries 进行分组聚合。Timeseries 使用指定的一组 Label 进行分组，然后使用指定的聚合函数对每组 Timeseries 的 value 做聚合计算。 比如，下面的查询返回每个 job 的 内存使用率总和：

```
sum(process_resident_memory_bytes) by (job)
```

更多参见 MetricsQL 的[聚合函数文档]({{< relref "./functions/aggregation.md" >}})。

## 计算速率
对于 [Counter]({{< relref "../../concepts.md#counter" >}}) 类型指标使用最广泛的的一个函数是 [rate]({{< relref "./functions/rollup.md#rate" >}})。
它对每一个 Timeseries 独立计算每秒的平均增长率。比如，下面的查询返回的是每一个 node_exporter 实例监控到的每秒平均入流量， `node_network_receive_bytes_total`指标是`node_exporter`暴露的一个指标。

```
rate(node_network_receive_bytes_total)
```

默认情况下，无论是 [Instant Query]({{< relref "../../quickstart.md#instant-query" >}}) 还是 [Range Query]({{< relref "../../quickstart.md#range-query" >}})，VictoriaMetrics 都使用`step`参数指定的作用范围，对作用范围内的样本执行`rate`计算。`rate`需要计算的时间间隔可以在一个中括号中指定。比如：

```
rate(node_network_receive_bytes_total[5m])
```

在这个例子中，VictoriaMetrics 使用指定的回溯窗口`5m`(5分钟)。来计算平均每秒增长。通常情况下回溯窗口越大，曲线图形就约平滑。

`rate`会保留 timeseries 中除了 Metric 名称之外的所有 Label。如果你想要保留 Metric 名称，就需要在`rate(...)`后面使用 [keep_metric_names]({{< relref "./_index.md#keeping-metric-name" >}}) 修改器。比如，下面的语句就是在计算`rate()`后保留 Metric 名称：

```plain
rate(node_network_receive_bytes_total) keep_metric_names
```

`rate()`能且只能用于 [Counter]({{< relref "../../concepts.md#counter" >}}) 类指标。对 [Gauge]({{< relref "../../concepts.md#gauge" >}}) 类型指标应用`rate`是没意义的。

## keep_metric_names
默认情况下，Metric 名称会在应用函数或[算数运算](#math)后被丢弃，因为它们已经失去了gg原始指标的含义。当函数作用于多个名称不同的时间序列时，可能会导致`duplicate time series`错误。这个错误可以使用`keep_metric_names`修改器来解决。

例如：

+ `rate({__name__=~"foo|bar"}) keep_metric_names`会在查询结算结果中保留`foo`和`bar`这 2 个 Metric 名称。
+ `({__name__=~"foo|bar"} / 10) keep_metric_names`会在查询结算结果中保留`foo`和`bar`这 2 个 Metric 名称。

