---
title: 数据写入
weight: 6
---

VictoriaMetrics 能够发现Prometheus兼容的目标地址并采集数据（通过 [PULL]({{< relref "./model.md#pull" >}}) 模式）。此外，VictoriaMetrics 可以接收使用下面这些常见的数据写入协议的数据（通过[PUSH]({{< relref "./model.md#push" >}})模式）

- [Prometheus`remote_write`API]({{< relref "./api.md" >}})
- [DataDog submit metrics API]({{< relref "./api.md" >}})
- [InfluxDB line protocol]({{< relref "./api.md" >}})
- [Graphite plaintext protocol]({{< relref "./api.md" >}})
- [OpenTelemetry http API]({{< relref "./api.md" >}})
- [OpenTSDB telnet put protocol]({{< relref "./api.md" >}})
- [OpenTSDB http /api/put protocol]({{< relref "./api.md" >}})
- [`/api/v1/import`可导入通过`/api/v1/export`导出的数据]({{< relref "./api.md" >}})
- [`/api/v1/import/native`可以导入通过`/api/v1/export/native`导出的数据]({{< relref "./api.md" >}})
- [`/api/v1/import/csv`导入 CSV 格式数据]({{< relref "./api.md" >}})
- [`/api/v1/import/prometheus` 导入 Prometheus Exposition 格式以及 Pushgateway 格式的数据]({{< relref "./api.md" >}})

请注意，大多数写入 API （除了 prometheus remote_write 和 OpenTelemetry） 都做了性能优化，且支持对数据的流式处理。这意味着客户端可以使用一个长链接发送无线的数据。
正因为如此，写入 API 可能不会返回给客户端解析错误，因为系统期望的是数据是持续无中断写入的。

作为替代，可以在服务端（VictoriaMetrics 单机版或 vminsert 组件）来查看解析错误，或者监控`vm_rows_invalid_total`指标（服务端组件暴露）的变动。