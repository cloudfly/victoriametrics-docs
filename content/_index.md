---
title: VictoriaMetrics 中文手册
date: 2024-11-01T18:45:18+08:00
keywords:
- victoriametrics
- prometheus
- opentelemetry
- 可观测
- 监控
- 分布式
description: VictoriaMetrics 中文文档手册，包含了 VictoriaMetrics 的运维和使用文档，以及可观测领域的经验分享
layout: hextra-home
---


<div class="hx-mt-6 hx-mb-6">
{{< hextra/hero-headline >}}
  分布式可观测系统解决方案&nbsp;<br class="sm:hx-block hx-hidden" />
{{< /hextra/hero-headline >}}
</div>

<div class="hx-mb-12">
{{< hextra/hero-subtitle >}}
	兼容 Prometheus、OpenTelemetry、InfluxDB、 Graphite 等主流数据协议
{{< /hextra/hero-subtitle >}}
</div>

<div class="hx-mb-6">
{{< hextra/hero-button text="开始学习" link="docs" >}}
</div>

<div class="hx-mt-6"></div>

{{< hextra/feature-grid >}}
  {{< hextra/feature-card
    link="/docs/quickstart"
    title="快速开始"
    subtitle="带你快速你了解 VictoriaMetrics 的搭建和使用。"
  >}}
  {{< hextra/feature-card
    link="/docs/query/metricsql"
    title="强大的 MetricsQL"
    subtitle="兼容 PromQL 的强大查询语言 MetricsQL。"
  >}}
  {{< hextra/feature-card
    link="/docs/write/api"
    title="兼容主流协议"
    subtitle="支持 Prometheus，OpenTelemetry，InfluxDB，Graphite，OpenTSDB，DataDog 等"
  >}}
  {{< hextra/feature-card
    link="/docs/ops/operation"
    title="日常运维指南"
    subtitle="介绍了对 VictoriaMetrics 日常运维中常见问题的解决方法"
  >}}
  {{< hextra/feature-card
    link="/docs/articles/mmap-slowdown-go"
    title="优质技术文章"
    subtitle="TSDB 领域的优质技术内容"
  >}}
{{< /hextra/feature-grid >}}