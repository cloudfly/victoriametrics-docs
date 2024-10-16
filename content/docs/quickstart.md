---
title: 快速开始
description: 用简短的内容和操作让一个用户快速的运行起 VictoriaMetrics 服务，并使用它完成基础的监控任务。
weight: 2
---

## 如何安装
VictoriaMetrics 有 2 种发布形式：

+ [单机版本]({{< relref "ops/single.md" >}}) - ALL-IN-ONE 的二进制形式，非常易于使用和维护。可以垂直扩展，并轻松处理百万级的 QPS 写入。
+ [集群版本]({{< relref "ops/cluster" >}}) - 一套组件，可用于构建水平可扩展的集群。

### 单机版
使用下面的命令下载最新版本的 VictoriaMetrics Docker 镜像，然后使用`8482`端口运行，并将数据存储在当前目录中的`victoria-metrics-data`目录下。

```shell
docker pull victoriametrics/victoria-metrics:latest
docker run -it --rm -v `pwd`/victoria-metrics-data:/victoria-metrics-data -p 8428:8428 victoriametrics/victoria-metrics:latest
```

用浏览器打开[`http://localhost:8428`](http://localhost:8428/)然后阅读[这些文档]({{< relref "./ops/single.md#operation" >}})。

### 集群版
下面的命令 clone 最新版本的 VictoriaMetrics 仓库，然后使用命令`make docker-cluster-up`启动 Docker 容器。更多的自定义启动项可以通过编辑[`docker-compose-cluster.yml`](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/deployment/docker/docker-compose-cluster.yml)实现。


```shell
git clone https://github.com/VictoriaMetrics/VictoriaMetrics && cd VictoriaMetrics
make docker-cluster-up
```

更多详情[请看这个文档](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/deployment/docker#readme)和[集群安装文档]({{< relref "ops/deploy.md#cluster" >}})

## 数据写入

VictoriaMetrics 支持常见的多种数据协议写入，包括 prometheus remote write、influxdb、opentsdb 等等。

### InfluxDB {#influxdb}
写入接口`/influx/write`或`/influx/api/v2/write`。
```bash
curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/influx/api/v2/write'
```
使用`/api/v1/export`接口查询刚写入的数据，返回内容如下：
```bash
# command
curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"measurement.*"}'
# response
{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1695902762311]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1695902762311]}
```

{{% doc-extra-label "/influx/write" %}}

### Prometheus Text Format

VictoriaMetrics 通过`/prometheus/api/v1/import`接口来接收 [Prometheus exposition text format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-based-format) 数据，以及接收 [Pushgateway 协议](https://github.com/prometheus/pushgateway#url)的数据

比如下面一行命令将 Prometheus Exposition Text Format 的指标数据写入到 VictoriaMetrics：

```bash
curl -d 'foo{bar="baz"} 123' -X POST 'http://localhost:8428/prometheus/api/v1/import/prometheus'
```

用下面的命令可验证写入的数据：
```bash
# command
curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"foo"}'

# response
{"metric":{"__name__":"foo","bar":"baz"},"values":[123],"timestamps":[1594370496905]}
```

下面的命令模拟 [pushgateway 写入协议](https://github.com/prometheus/pushgateway#url)，将一条 metric 带上`{job="my_app",instance="host123"}`Label 写入

```bash
curl -d 'metric{label="abc"} 123' -X POST 'http://localhost:8428/api/v1/import/prometheus/metrics/job/my_app/instance/host123'
```

`/api/v1/export`接口将返回如下数据：
```json
{"metric":{"__name__":"metric","job":"my_app","instance":"host123","label":"abc"},"values":[123],"timestamps":[1729084141050]}
```

### Prometheus Remote Write

VictoriaMetrics 在`/prometheus/api/v1/write`或`/prometheus`接口上接收处理 [Prometheus Remote Write](https://prometheus.io/docs/specs/remote_write_spec/) 协议写入的数据。

可以在 Prometheus 的配置文件中（通常是在`/etc/prometheus/prometheus.yml`中）配置上`remote_write`地址，它就会将数据发送给 VictoriaMetrics:
```yaml
remote_write:
  - url: http://<victoriametrics-addr>:8428/prometheus/api/v1/write
```

### 其他

VictoriaMetrics 还支持其他很多种数据写入协议，更多内容请参阅[这篇文档]({{< relref "write/api.md" >}})


## 数据查询
VictoriaMetrics 提供了 HTTP 接口来处理查询请求。这些接口会被各种联合使用，比如 [Grafana](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#grafana-setup)。这些 API 通用会被 [VMUI]({{{< relref "components/vmui" >}}) （用来查看并绘制请求数据的用户界面）使用。

我们可以使用上面提到的`/api/v1/export`将原始写入数据导出查看，但这通常仅用于问题排查，而非正式使用。

大多数情况我们都是使用 [MetricsQL]({{< relref "query/metricsql" >}}) 来查询数据。 它是用来在 VictoriaMetrics 上查询数据的一种查询语言。一个类 [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics) 的查询语言，但它扩展了很多强大的处理函数和特性来处理时序数据。

### Instant Query

我们使用`/api/v1/query`来查询上面 [InfluxDB]("#influxdb") 部分写入的即时数据。

```bash
curl "http://localhost:8428/api/v1/query?query=measurement_field1"
```
该命令将得到查询结果：
```json
{
  "status": "success",
  "data": {
    "resultType": "vector",
    "result": [
      {
        "metric": {
          "__name__": "measurement_field1"
        },
        "value": [
          1652169780, 
          "3"
        ]
      }
    ]
  }
}
```

### Range Query {#range-query}

我们可以使用`/api/v1/query_range`查询上面 [InfluxDB]("#influxdb") 部分写入的历史数据

```bash
curl "http://localhost:8428/api/v1/query_range?query=measurement_field1&step=1m&start=-6h&end=now"
```

将得到类似如下数据格式的结果：

```json
{
  "status": "success",
  "data": {
    "resultType": "matrix",
    "result": [
      {
        "metric": {
          "__name__": "measurement_field1"
        },
        "values": [
          [
            1652169600,
            "1"
          ],
          [
            1652169660,
            "2"
          ],
          [
            1652169720,
            "3"
          ],
          [
            1652169780,
            "3"
          ],
          [
            1652169840,
            "7"
          ],
          [
            1652169900,
            "7"
          ],
          [
            1652170620,
            "4"
          ]
        ]
      }
    ]
  }
}
```

更多数据查询详情，请[参考这里]({{< relref "query" >}})。


## 监控告警

### 监控 {#monitoring}

每个 VictoriaMetrics 组件都会在`/metrics`接口上暴露自己的 Prometheus 格式指标，其中包含有关性能和健康状态的各种详细信息。这些指标可以通过`vmagent`或`Prometheus`进行抓取。

对于单机版，当`-selfScrapeInterval`启动参数设置为大于`0`时，它会自动抓取自己的`/metrics`并存储。例如，`-selfScrapeInterval=10s`表示每`10`秒一次的自动抓取`/metrics`数据并存储。更多内容[参见这里]({{< relref "ops/single.md#metrics" >}})。


VictoriaMetrics 团队为核心组件准备了一系列的 [Grafana Dashboard](https://grafana.com/orgs/victoriametrics/dashboards)。每个 Dashboard 中都包含很多有用的信息和提示。建议使用安装这些 Dashboard 并保持更新。

{{< callout type="info" >}}
  注：建议使用另外一套独立的监控系统，去监控生产环境的 VictoriaMetrics。而不是让它自己监控自己。
{{< /callout >}}

更多详细内容请参考[这篇文章](https://victoriametrics.com/blog/victoriametrics-monitoring)。


### 告警
我们不可能一直盯着监控图表来跟踪所有变化，这就是我们需要告警的原因。[vmalert]({{< relref "components/vmalert" >}}) 可以基于 PromQL 或 MetricsQL 查询语句创建一系列条件，当条件触发时候会发送自动发送通知。

## 发布到生产

如果要在生产环境真正使用 VictoriaMetrics，我们有以下一些建议。

### 容量规划
请阅读[集群版]({{< relref "ops/cluster#capacity" >}})和[单机版]({{< relref "ops/single.md#capacity" >}})文档中的容量规划部分。

容量规划需要依赖于[监控](#monitoring)，所以你应该首先配置下监控。搞清楚 VictoriaMetrics 在你所用的机型上的资源使用情况，在进行性能调优和容量规划。 但这些前提是，你需要知道[活跃时序系列]({{< relref "faq.md#what-is-active-timeseries" >}})，[高流失率]({{< relref "faq.md#what-is-high-churn-rate" >}})，[基数]({{< relref "faq.md#what-is-high-cadinality" >}})，[慢写入]({{< relref "faq.md#what-is-slow-insert" >}})这些基础技术概念，这些关键指标都会在 [Grafana Dashboard](https://grafana.com/orgs/victoriametrics/dashboards) 中呈现。

### 数据安全
建议阅读下面几篇内容：

+ [多副本和数据可靠性]({{< relref "ops/single.md#replication" >}})
+ [Why replication doesn't save from disaster?](https://valyala.medium.com/speeding-up-backups-for-big-time-series-databases-533c1a927883)
+ [数据备份]({{< relref "ops/single.md#backup" >}})

### 配置限制
为了避免资源使用过度或性能下降，必须设置限制：

+ [资源使用限制]({{< relref "faq.md#how-to-limit-memory-usage" >}})
+ [基数限制]({{< relref "ops/single.md#cadinality" >}})

### 安全建议
+ [单机版安全建议]({{< relref "ops/single.md#security" >}})
+ [集群版安全建议]({{< relref "ops/cluster#security" >}})
