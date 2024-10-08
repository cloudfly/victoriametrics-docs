---
title: 快速开始
weight: 2
---

## 如何安装
VictoriaMetrics 有 2 种发布形式：

+ [单机版本]({{< relref "ops/single.md" >}}) - ALL-IN-ONE 的二进制形式，非常易于使用和维护。可完美地垂直扩展，并且轻松处理百万级的QPS写入。
+ [集群版本]({{< relref "ops/cluster" >}}) - 一套组件，可用于构建水平可扩展集群。


### Docker

#### 单机版
使用下面的命令下载最新版本的 VictoriaMetrics Docker 镜像，然后使用`8482`端口运行，并将数据存储在当前目录中的 `victoria-metrics-data` 目录下。

```shell
docker pull victoriametrics/victoria-metrics:latest
docker run -it --rm -v `pwd`/victoria-metrics-data:/victoria-metrics-data -p 8428:8428 victoriametrics/victoria-metrics:latest
```

用浏览器打开 [http://localhost:8428](http://localhost:8428/) 然后阅读[这些文档]({{< relref "ops/single.md#operation" >}})。

#### 集群版
下面的命令 clone 最新版本的 VictoriaMetrics 仓库，然后使用命令`make docker-cluster-up`启动 Docker 容器。更多的自定义启动项可以通过编辑[docker-compose-cluster.yml](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/deployment/docker/docker-compose-cluster.yml)实现。


```shell
git clone https://github.com/VictoriaMetrics/VictoriaMetrics && cd VictoriaMetrics
make docker-cluster-up
```

更多详情[请看这个文档](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/deployment/docker#readme)和[集群安装文档]({{< relref "ops/cluster#operation" >}})

### 其他
单机版的 VictoriaMetrics 还有以下几种提供方式：

+ [Managed VictoriaMetrics at AWS](https://aws.amazon.com/marketplace/pp/prodview-4tbfq5icmbmyc)
+ [Snap packages](https://snapcraft.io/victoriametrics)
+ [Helm Charts](https://github.com/VictoriaMetrics/helm-charts#list-of-charts)
+ [二进制](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)
+ [源代码](https://github.com/VictoriaMetrics/VictoriaMetrics)。 参见[如何构建源代码](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#how-to-build-from-sources)
+ [VictoriaMetrics on Linode](https://www.linode.com/marketplace/apps/victoriametrics/victoriametrics/)
+ [VictoriaMetrics on DigitalOcean](https://marketplace.digitalocean.com/apps/victoriametrics-single)

只需要下载 VictoriaMetrics 然后跟随[这些步骤]({{< relref "ops/single.md#execute" >}})把 VictoriaMetrics 运行起来，

## 数据写入

VictoriaMetrics 支持常见的多种数据协议写入，包括 prometheus remote write、influxdb、opentsdb 等等。

### InfluxDB {#influxdb}
写入接口`/api/v1/write` 或 `/influx/api/v2/write`。
```bash
curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/api/v2/write'
```
使用`/api/v1/export`接口查询写入内容会返回如下数据：
```bash
{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1695902762311]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1695902762311]}
```


### OpenTSDB
需要在运行 VictoriaMetrics 时候使用`-opentsdbHTTPListenAddr`参数来开启针对 OpenTSDB 协议的 HTTP写入接口`/api/put`。例如，下面的命令将 OpenTSDB 的 HTTP 写入接口开在 4242 端口上：

```bash
/path/to/victoria-metrics-prod -opentsdbHTTPListenAddr=:4242
```

使用下面的命令可写入单条数据：

```bash
curl -H 'Content-Type: application/json' -d '{"metric":"x.y.z","value":45.34,"tags":{"t1":"v1","t2":"v2"}}' http://localhost:4242/api/put
```
写入多条数据：
```bash
curl -H 'Content-Type: application/json' -d '[{"metric":"foo","value":45.34},{"metric":"bar","value":43}]' http://localhost:4242/api/put
```

使用`/api/v1/export`接口来查看刚刚写入的数据：
```bash
# command
curl -G 'http://localhost:8428/api/v1/export' -d 'match[]=x.y.z' -d 'match[]=foo' -d 'match[]=bar'
# response
{"metric":{"__name__":"foo"},"values":[45.34],"timestamps":[1566464846000]}
{"metric":{"__name__":"bar"},"values":[43],"timestamps":[1566464846000]}
{"metric":{"__name__":"x.y.z","t1":"v1","t2":"v2"},"values":[45.34],"timestamps":[1566464763000]}
```

可在写入 URL `/api/put` 加上`extra_label`参数为所有写入数据注入额外的 Label。比如使用`/api/put?extra_label=foo=bar`URL写数据，系统会为每条写入的 Metric 数据追加`{foo="bar"}`Label

更多数据写入详情，请[参考这里](https://www.victoriametrics.com.cn/victoriametrics/shu-ju-xie-ru)。

### Prometheus Exposition Format

VictoriaMetrics 通过`/api/v1/import/prometheus`接口来接收 [Prometheus exposition format](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-based-format)数据，以及接收 [Pushgateway 协议](https://github.com/prometheus/pushgateway#url)的数据

比如下面一行命令将 Prometheus Exposition Format 的指标数据写入到 VictoriaMetrics：

```bash
curl -d 'foo{bar="baz"} 123' -X POST 'http://localhost:8428/api/v1/import/prometheus'
```

用下面的命令可验证写入的数据：
```bash
# command
curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"foo"}'

# response
{"metric":{"__name__":"foo","bar":"baz"},"values":[123],"timestamps":[1594370496905]}
```

下面的命令模拟 [pushgateway 写入协议](https://github.com/prometheus/pushgateway#url)，将一条metric带上`{job="my_app",instance="host123"}` Label 写入

```bash
curl -d 'metric{label="abc"} 123' -X POST 'http://localhost:8428/api/v1/import/prometheus/metrics/job/my_app/instance/host123'
```

### Prometheus Remote Write

VictoriaMetrics 在`/api/v1/write`接口上接收处理 [Prometheus Remote Write](https://prometheus.io/docs/specs/remote_write_spec/) 协议写入的数据。

可以在 Prometheus 的配置文件中（通常是在`/etc/prometheus/prometheus.yml`中）配置上 remote_write 地址，它就会将数据发送给 VictoriaMetrics:
```yaml
remote_write:
  - url: http://<victoriametrics-addr>:8428/api/v1/write
```

### 其他

VictoriaMetrics 还支持其他很多种数据写入协议，更多内容请参阅[这篇文档]({{< relref "write/api.md" >}})


## 数据查询
VictoriaMetrics 提供了 HTTP 接口来处理查询请求。这些接口会被各种联合使用，比如 [Grafana](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#grafana-setup)。这些 API 通用会被 [VMUI]({{{< relref "components/vmui" >}}) （用来查看并绘制请求数据的用户界面）使用。

我们可以使用上面提到的`/api/v1/export`将原始写入数据导出查看，但这通常仅用于问题排查，而非正式使用。

大多数情况我们都是使用 [MetricsQL]({{< relref "query/metricsql" >}}) 来查询数据。 这是用来在 VictoriaMetrics 上查询数据的一种查询语言。 一个类 [PromQL](https://prometheus.io/docs/prometheus/latest/querying/basics) 的查询语言，但它拥有很多强大的处理函数和特性来处理时序数据。

### Instant Query

我们使用`/api/v1/query`来查询上面 [InfluxDB]("#influxdb") 部分写入的即时数据。

```bash
curl "http://localhost:8428/api/vq/query?query=measurement_field1"
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

### Range Query

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

## 告警
我们不可能一直盯着监控图表来跟踪所有变化，这就是我们需要告警的原因。[vmalert]({{< relref "components/vmalert" >}}) 可以基于 PromQL 或 MetricsQL 查询语句创建一系列条件，当条件触发时候会发送自动发送通知。

## 发布到生产

如果要在生产环境真正使用 VictoriaMetrics，我们有以下一些建议。

### 监控 {#monitoring}
每个 VictoriaMetrics 组件都会暴露自己的指标，其中包含有关性能和健康状态的各种详细信息。组件的文档中都有一板块专门介绍监控，其中解释了组件的监控指标的含义，以及如何去监控。[比如这里]({{< relref "ops/single.md#metrics" >}})。

VictoriaMetrics 团队为核心组件准备了一系列的 [Grafana Dashboard](https://grafana.com/orgs/victoriametrics/dashboards)。每个 Dashboard 中都包含很多有用的信息和提示。建议使用安装这些 Dashboard 并保持更新。

针对[单机版]({{< relref "ops/single.md" >}})和[集群版]({{< relref "ops/cluster" >}})的VM，还有一系列的告警规则来帮助我们定义和通知系统问题。

有一个经验是：使用额外的一套独立的监控系统，去监控生产环境的VictoriaMetrics。而不是让它自己监控自己。

更多详细内容请参考[这篇文章](https://victoriametrics.com/blog/victoriametrics-monitoring)。

### 容量规划
请阅读[集群版]({{< relref "ops/cluster#capacity" >}})和[单机版]({{< relref "ops/single.md#capacity" >}})文档中的容量规划部分。

容量规划需要依赖于[监控](#monitoring)，所以你应该首先配置下监控。搞清楚资源使用情况以及VictoriaMetrics的性能的前提是，需要知道[活跃时序系列]({{< relref "faq.md#what-is-active-timeseries" >}})，[高流失率]({{< relref "faq.md#what-is-high-churn-rate" >}})，[基数]({{< relref "faq.md#what-is-high-cadinality" >}})，[慢写入]({{< relref "faq.md#what-is-slow-insert" >}})这些基础技术概念，他们都会在 [Grafana Dashboard](https://grafana.com/orgs/victoriametrics/dashboards) 中呈现。

### 数据安全
建议阅读下面几篇内容：

+ [多副本和数据可靠性]({{< relref "ops/single.md#replication" >}})
+ [Why replication doesn't save from disaster?](https://valyala.medium.com/speeding-up-backups-for-big-time-series-databases-533c1a927883)
+ [数据备份]({{< relref "ops/single.md#backup" >}})

### 配置限制
为了避免资源使用过度或性能下降，必须设置限制：

+ [资源使用限制]({{< relref "faq.md#how-to-limit-memory-usage" >}})
+ [基数限制]({{< relref "ops/single.md#cadinality-limit" >}})

### 安全建议
+ [单机版安全建议]({{< relref "ops/single.md#security" >}})
+ [集群版安全建议]({{< relref "ops/cluster#security" >}})


然后再阅读 [Prometheus](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#prometheus-setup) 和 [Grafana 配置](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben#grafana-setup)文档。

