---
title: 改进 Gorilla 压缩算法
date: 2024-11-02T20:49:24+08:00
description: 本文介绍了 VictoriaMetrics 所使用的时序压缩算法，介绍了 Gorilla 算法的基本原理，已经 VictoriaMetrics 对它做了哪些改进。
weight: 1
---

每个读过论文《[Gorilla: A fast, scalable, in-memory time series database](http://www.vldb.org/pvldb/vol8/p1816-teller.pdf)》的人都知道：
- 时序数据可以利用其顺序递增的特性进行压缩，进而降低内存、磁盘空间和磁盘 IO 的使用量。
- Gorilla 压缩算法几乎成为了 TSDB 领域的标准，比如：
  - [Prometheus uses Gorilla](https://github.com/prometheus/tsdb/blob/99703b3269a1b870e04524e97b807319e1540720/README.md)
  - [InfluxDB uses Gorilla](https://github.com/influxdata/influxdb/blob/966f2ff9f3cc330334f09426e4a739dc05ee9d33/tsdb/tsm1/float.go#L23)
  - [M3 is inspired by Gorilla](https://github.com/m3db/m3/blob/b27738bb35578fff396a67dfc2797f972f203e5f/docs/m3db/architecture/engine.md#time-series-compression-m3tsz)
  - [TimescaleDB uses Gorilla](https://blog.timescale.com/blog/building-columnar-compression-in-a-row-oriented-database/)
    

有没有可能存在比 Gorilla 压缩比更高的压缩算法呢？

## Gorilla 压缩算法介绍
    
让我们看看原始的 Gorilla 算法有哪些优缺点。

该算法包括以下步骤：
* 按单个时间序列对数据进行分组。
* 按时间戳对每个时间序列的 (timestamp, value) 数据点进行排序。
* 使用 [delta-encoding](https://en.wikipedia.org/wiki/Delta_encoding) 对排序后的 timestamp 进行编码。它把大 timestamp 替换为与前值的偏差。与原始 timestamp 相比，偏差数值很小，需要的编码空间更少。
* 对后面`Float`类型的 value 的`XOR`操作。Gorilla 论文声称这通常会让结果值的二进制表示中包含大量的`0`前缀或后缀。这样的值需要的编码空间更少。
    
Gorilla 对典型的时间序列数据能做到3到8倍的压缩，即将每个`16`字节的`(timestamp, value)`数据点压缩到`2`到`5`字节。压缩比率取决于原始数据的随机性，随机性越高，压缩比率越低。

## Gorilla 压缩结果分析

Gorilla 压缩算法看起来很稳定，除了最后一步对`Float`类型的 value 进行`XOR`运算。让我们看看范围`[0.0 … 1.1]`内，步长为`0.1` 的后续值的`XOR`结果：
> a 代表当前值，b 代表下一个值
```
0.0, a=0000000000000000, b=3FB999999999999A, a^b=3FB999999999999A  
0.1, a=3FB999999999999A, b=3FC999999999999A, a^b=0070000000000000  
0.2, a=3FC999999999999A, b=3FD3333333333334, a^b=001AAAAAAAAAAAAE  
0.3, a=3FD3333333333334, b=3FD999999999999A, a^b=000AAAAAAAAAAAAE  
0.4, a=3FD999999999999A, b=3FE0000000000000, a^b=003999999999999A  
0.5, a=3FE0000000000000, b=3FE3333333333333, a^b=0003333333333333  
0.6, a=3FE3333333333333, b=3FE6666666666666, a^b=0005555555555555  
0.7, a=3FE6666666666666, b=3FE9999999999999, a^b=000FFFFFFFFFFFFF  
0.8, a=3FE9999999999999, b=3FECCCCCCCCCCCCC, a^b=0005555555555555  
0.9, a=3FECCCCCCCCCCCCC, b=3FEFFFFFFFFFFFFF, a^b=0003333333333333  
1.0, a=3FEFFFFFFFFFFFFF, b=3FF1999999999999, a^b=001E666666666666
```

如你所见，大多数`a^b`结果的`0`后缀位数量并不多。这意味着对于典型的浮点值，压缩比率并不像 Gorilla 论文中宣传的那样好。你可以在[这个页面](https://play.golang.org/p/aVOrifM4e5h)验证结果并使用你自己的数据集进行测试。

## 改进时序数据的压缩比

显而易见的改进是，在应用`XOR`编码之前，将浮点值转换为整数。下面包含范围`[0 … 11]`内，步长为`1`的后续整数值的`XOR`结果：

```
0, a=0000000000000000, b=0000000000000001, a^b=0000000000000001  
1, a=0000000000000001, b=0000000000000002, a^b=0000000000000003  
2, a=0000000000000002, b=0000000000000003, a^b=0000000000000001  
3, a=0000000000000003, b=0000000000000004, a^b=0000000000000007  
4, a=0000000000000004, b=0000000000000005, a^b=0000000000000001  
5, a=0000000000000005, b=0000000000000006, a^b=0000000000000003  
6, a=0000000000000006, b=0000000000000007, a^b=0000000000000001  
7, a=0000000000000007, b=0000000000000008, a^b=000000000000000F  
8, a=0000000000000008, b=0000000000000009, a^b=0000000000000001  
9, a=0000000000000009, b=000000000000000A, a^b=0000000000000003
```

现在，从压缩的角度来看，`a^b` 结果要好得多，它们包含大量的`0`前缀位，所以编码后需要的空间更少。可以在[这个页面](https://play.golang.org/p/0LnlBDz_pDP)上使用你自己的数据进行验证测试。

如何将步长为`0.1`的`[0.0 … 1.1]`序列转换为步长为`1`的`[0 … 11]`序列？乘以`10`！  
所有的浮点数序列都可以通过乘以`10^N`转换为一个整数序列，其中`N`是时间序列中所有值的最大小数点位数。唯一的问题是乘积结果可能会溢出。
如何处理这个问题？通过除以`10^M`来规范化整数，也就是损失小数点最后的一些位的精度。其中`M`是允许转换成整数后还能保证`64`位不溢出的最小值。

为什么要乘以`10^N`而不是使用的[标准浮点编码方案](https://en.wikipedia.org/wiki/Double-precision_floating-point_format)中的`2^N`？因为我们是人类，更喜欢将公制值四舍五入到小数点，而不是二进制点 :) 这为更好的压缩比率提供了机会，正如我们上面所看到的。

## Gauges 和 Counters

最常见的指标有 2 大类：
- Gauge: 可以是随时间上下波动的任意值，比如内存使用率，CPU使用率，速度，温度，压力等等。
- Counter: 随时间非递减的序列，不如请求总数，总字节数，总距离等。
    
Counter 可以通过[`delta-encoding`](https://en.wikipedia.org/wiki/Delta_encoding)转换为 Gauge。它用数值增长的速度来替代原始值。由于增量通常小于原始值，这减少了存储时间序列所需的位数，从而提高了计数器的压缩比率。
    

## 通用压缩算法

上述方案相比原始的 Gorilla 算法为浮点值提供了更好的压缩比。但是通过对编码后的数据进一步使用通用压缩算法，可以进一步提高压缩比率。通用压缩算法如 [zstd](https://github.com/facebook/zstd) 擅长压缩重复率高的低熵数据。在对时间序列数据应用类似 Gorilla 的编码后，数据就会变得重复率高，即低熵。唯一的缺点是通用压缩会增加 CPU 用量。但相对与时间序列数据库代码的其他模块所消耗的 CPU 用量，这点增加是可以忽略的。

## 结论 {#conclusion}

Facebook 开源的 Gorilla 压缩算法的压缩比可通过以下几个简单的方法提升：
- 对浮点数乘以`10^X`，将其转换成整数。
- 把 Counter 类型数据使用[`delta-encoding`](https://en.wikipedia.org/wiki/Delta_encoding)转换成 Gauge 类型
- 使用通用的压缩算法，对编码后的数据进一步压缩。
    
这些技术相比竞争对手为 VictoriaMetrics 提供了更好的压缩率，它将典型的 [node_exporter](https://github.com/prometheus/node_exporter) 时间序列数据压缩到 [每个数据点 0.4 字节](https://medium.com/@valyala/measuring-vertical-scalability-for-time-series-databases-in-google-cloud-92550d78d8ae)。这比 Prometheus 使用原始 Gorilla 压缩算法对相同数据的每个数据点`4`字节好`10`倍。