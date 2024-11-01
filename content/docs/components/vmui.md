---
title: "vmui"
date: 2024-11-01T18:42:42+08:00
weight: 3
---

VictoriaMetrics 提供了一个 UI 界面用于问题定位和查数据。该 UI 地址在`http://victoriametrics:8428/vmui`(集群版在`http://<vmselect>:8481/select/<accountID>/vmui/`)。
该 UI 界面可以通过图表或表格的方式查看指标数据，支持以下功能：

- 查询类（Explorer）：
  - [Metrics Explorer](#metrics-explorer)：自动使用查询的指标数据绘制图表。
  - [Cardinality Explorer](#cardinality-explorer)：展示 TSDB 中指标数据的统计信息。
  - [Top Queries](#top-queries)：展示查询频率最高的语句。
  - [Active Queries](#active-queries)：展示当前正在执行中的查询语句。

- 工具类（Tools）：
  * [Trace analyzer]({{< relref "../ops/single.md#trace" >}}) - 查看 JSON 格式的查询语句执行 Trace 信息
  * [Query analyzer]({{< relref "../ops/single.md#trace" >}}) - 查看查询结果及查询执行的的 Trace 信息
  * [WITH expressions playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/#/expand-with-exprs) - 测试 WITH 表达式的工作原理
  * [Metric relabel debugger](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/#/relabeling) - 验证 [relabeling](https://docs.victoriametrics.com/#relabeling) 配置。


## Top Queries

Top Queries 主要用来帮助定位一下问题：
* 执行频率最高的查询。
* 平均执行时间最长的查询。
* 总执行消耗时间最长的查询。   

这些信息是从 HTTP 接口`/api/v1/status/top_queries`上获取的。

## Active Queries

展示当前正在运行中的查询。它每个查询提供了以下信息：
- 查询语句本身，[/api/v1/query_range]({{< relref "../query/_index.md#range-query" >}}) 的请求参数，包括时间范围，以及`step`参数等。
- 查询的执行耗时。 
- 发送请求的客户端地址    

这些信息是从 HTTP 接口`/api/v1/status/active_queries`上获取的。

## Metrics Explorer

用于查询特定`job`/`instance`暴露的指标内容。

1.  打开地址`http://victoriametrics:8428/vmui/`.
2.  点击 `Explore Prometheus metrics` 菜单.
3.  选择想要查询的`job`。
4.  \[可选\] 选择要查询的目标`instance`
5.  选择要查询和对比的指标
    
可以在右上角选择要查询的时间范围。

## Cardinality Explorer

VictoriaMetrics 提供了查看 TSDB 指标基数的功能：
*   定位 series 数量最多的指标名
*   定位 series 数量最多的 Label
*   定位特定 Label(通过`focusLabel`指定) 中 series 最多的 Value
*   定位 series 最多的`label_name=label_value`
*   定位 series 最多的 Labels，注意集群版展示的唯一Series数量可能会比实际的少，因为系统内部实现[存在限制](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/5a6e617b5e41c9170e7c562aecd15ee0c901d489/app/vmselect/netstorage/netstorage.go#L1039-L1045) 

默认情况下，Cardinality Explorer 分析当天的 timeseries，可以在右上角切换日期。默认情况下，可选的日期就都是可以进行分析的。我们也可以通过[series selector]({{< relref "../query/metricsql/basic.md#filter" >}})限制统计分析的范围。

Cardinality Explorer 基于接口 [/api/v1/status/tsdb]({{< relref "../query/api.md#apiv1statustsdb-tsdb-stats" >}}) 构建的。

可以在 [cardinality explorer playground](https://play.victoriametrics.com/select/accounting/1/6a716b0f-38bc-4856-90ce-448fd713e3fe/prometheus/graph/#/cardinality) 中试用。 也可以在[这里](https://victoriametrics.com/blog/cardinality-explorer/)查看下 Cardinality Explorer 的使用教程。

### 统计结果准确性

在[集群版]({{< relref "../ops/cluster.md" >}})里，每个 vmstorage 独立存储 timeseries 数据。vmselect 组件通过 [/api/v1/status/tsdb]({{< relref "../query/api.md#apiv1statustsdb-tsdb-stats" >}}) 从每一个 vmstorage 实例上获取结果，然后将每个 timeseries 的统计结果合并累加在一起。这就可能导致最终的统计结果比用户的实际数据多，因为 vmstorage 可能会因为[多副本]({{< relref "../ops/cluster.md#replication" >}})和[Reroute]({{< relref "../ops/cluster.md#availability" >}})机制导致同一个 timeseries 在不同的 vmstorage 上都存在。