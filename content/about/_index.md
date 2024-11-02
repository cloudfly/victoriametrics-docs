---
title: ""
date: 2024-11-02T19:23:18+08:00
toc: false
description: VictoriaMetrics 中文手册以及作者的相关介绍
excludeSearch: true
sidebar:
  exclude: true
comments: true
breadcrumbs: false
math: false
cascade:
  type: blog
---

## 关于本书
本书大部分内容都源自官方文档，但并没有对原文进行逐字逐句地翻译；对于冗余啰嗦，或是推广性质的，以及企业版特性内容会被省略掉，以减少一些学习干扰。  

内部也加了一些个人撰写的内容片段，一些是为了加强理解，另一些是分享一些完整的实践经验；后者会在标题处注明`（非官方）`，比如[这里]({{< relref "/docs/write/model.md#design-for-company" >}})。

此外，对官方文档的结构也会进行重新排版，因为本人近两年经常翻阅官方文档，感觉其文档结构比较混乱；来来回回翻阅了数十次还是经常找不到想要的内容，每次只能靠搜索。  

## 关于作者
本人在可观测方向工作了也快十年了，亲身经历了该方向技术的快速演变发展，走过很多弯路，掉过不少坑。数据存储问题一直是这个方向的一大技术难题，从最早期用 MySQL + Redis 或 Mongo 或 Graphite，到后来 TSDB 领域出现了 InfluxDB、Prometheus、OpenTSDB 等基于 LSM Tree 或列式存储的数据库方案，再到后来出现了 Thanos，M3DB 等针对 Prometheus 的开源分布式解决方案，到现在还出现很多使用 Clickhouse 作为时序数据存储方案。  
可是当我们遇到真正的大数据量时，这些系统表现总是有些差强人意，有时候不得不付出高昂的维护成本或二次开发，才能让系统勉强稳定。

2022 年初接触到了 VictoriaMetrics ，其性能、稳定性以及代码质量都让我很是佩服，作者 [valyala](https://github.com/valyala) 早期也开发了 [fasthttp](https://github.com/valyala/fasthttp) 等知名的 Go 开发库，技术功底相当扎实。  
VictoriaMetrics 几乎彻底地把我从 5千万 QPS 的高压需求中解脱了出来；在存储技术上它参考了 Clickhouse 的 MergeTree，然后针对 timeseries 领域做了诸多针对性优化。在阅读其源码时，也发现了很多共鸣的设计理念。
kk
之前有朋友创业，向我咨询 K8S 监控的解决方案。一番探讨后，他表示没想到这个方向水还挺深，这些踩坑经验还是很宝贵了。后来想着分享出来也不错。而且可观测方向的工作近期要告一段落了，后面计划从事其他业务方向，写这个书册也算是个积累总结吧，留个念想。

## 联系方式

{{< cards >}}
  {{< card link="/about" image="./wechat.jpg" title="加好友备注：vm" subtitle="邮箱：chenyunfei.cs@gmail.com" >}}
{{< /cards >}}