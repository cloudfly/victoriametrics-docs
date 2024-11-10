---
title: "VictoriaMetrics 中文手册"
date: 2024-11-10T12:56:27+08:00
---

## VictoriaMetrics 是什么？

VictoriaMetrics 是一个快速、经济高效且可扩展的监控解决方案和时间序列数据库。

VictoriaMetrics 提供二进制发布版、Docker镜像、Snap软件包和[源代码](https://github.com/victoriaMetrics/VictoriaMetrics)。 并支持可水平扩展的[集群版本]({{< relref "./ops/cluster.md" >}})。

了解更多关于 VictoriaMetrics 的[核心概念]({{< relref "./concepts.md" >}})，并按照[快速开始]({{< relref "./quickstart.md" >}})获得更好的体验。


## 可观测有时什么？（非官方）

可观测性（Observability）是一种通过分析系统外部输出结果推断及衡量系统内部状态的能力。在互联网技术领域内，这里的外部输出结果通常指的就是 Log、Metric、Trace、Event。

VictoriaMetrics 主要是针对 Metric 方向提供了可水平扩展的高性能解决方案，它还有另外一个兄弟系统 VictoriaLogs 为日志提供存储查询的分布式解决方案，更多细节可以[阅读官网](https://docs.victoriametrics.com/victorialogs/quickstart/)。

早期监控日志都是在运维体系内建设，因为指标和日志是运行维护一个系统的必备品。后期随着微服务架构的出现，问题定位变得尤其复杂，Trace 技术开始出现，其技术架构实现上和 Log、Metric 有很多类似的部分，所以很多公司都开始成立独立团队把Log、Metric、Trace放在一起，作为可观测方向统一建设。

随着一个公司内运维和运营系统的平台化建设，当白屏化操作进入一定阶段后，Event 数据类型也开始成为可观测方向的一员。
因为系统的白屏化操作比例较高的情况下，平台操作很容易成为一次事故的诱因；正是因为源头是平台操作引起的，系统很容易把操作的上下文一次性收集完整（相比于在终端上敲命令），而无需事后复杂的关联分析。  
所以对于一个庞大的技术架构体系，平台化能力越完善，稳定性通常也会越容易做好；而 Event 从技术角度上看，本质上属于带有更丰富上下文信息的结构化日志数据；它的数据量很小，技术并难度不高，但对加速排障的撬动效果却很大。