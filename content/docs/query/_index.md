---
title: 数据查询
weight: 5
---

VictoriaMetrics 提供了一个 [HTTP API]({{< relref "http.md" >}}) 用于处理数据查询。这些 API 被用于各种集成使用，例如[Grafana](https://docs.victoriametrics.com/single-server-victoriametrics/#grafana-setup)。相同的 API 也被 [VMUI]({{< relref "../components/vmui.md" >}}) 使用，VMUI 是一个用于查询和可视化指标的图形用户界面。

该 API 包含两个主要的处理程序，用于处理 [Instant Query(即时查询)]({{< relref "./http.md#instant-query" >}})和 [Range Query(范围查询)]({{< relref "./http.md#range-query" >}})。


## 时间格式 {#timestamp}

VictoriaMetrics 在查询和导出接口中会接收`time`,`start`,`end`参数。系统这些时间参数支持如下几种写法：

1. 秒级 Unix 时间戳允许在小数点后面加上毫秒精度。比如`1562529662.678`。
2. Unix 时间戳可以是毫秒级。比如：`1562529662678`。
3. [RFC3339](https://www.ietf.org/rfc/rfc3339.txt)。比如，`2022-03-29T01:02:03Z`或`2022-03-29T01:02:03+02:30`。
4. 部分RFC3339。比如：`2022`,`2022-03`,`2022-03-29`,`2022-03-29T01`,`2022-03-29T01:02`, `2022-03-29T01:02:03`。这些字符串会按照本地时区解析。也可以在这类写法中使用`Z`(UTC),`+hh:mm`或`-hh:mm`来改变时区。比如，`2022-03-01Z`代表 UTC 时区，而`2022-03-01+06:30`代表在`06:30`时区的`2022-03-01`。
5. 基于当前时间的相对时间。比如，`1h5m`,`-1h5m`或`now-1h5m`都表示1小时5分钟之前，其中`now`代表当前时间。 