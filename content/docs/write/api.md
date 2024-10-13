---
title: 写入 API
weight: 10
---

## 单机版

### 采集 Prometheus exporters（比如 [node-exporter](https://github.com/prometheus/node_exporter)）

VictoriaMetrics 可作为 Prometheus 的直接替代品，用于根据规范采集在`prometheus.yml`配置文件中配置的目标。 只需将`-promscrape.config`命令行参数设置为`prometheus.yml`配置文件的路径，VictoriaMetrics 就会开始抓取配置的目标。 如果所提供的配置文件包含不支持的选项，那么要么从文件中删除这些配置项，要么将`-promscrape.config.strictParse=false`命令行参数传递给 VictoriaMetrics，这样它就会忽略不支持的配置项。

`-promscrape.config`指向的文件可能包含`%{ENV_VAR}`占位符，这些占位符会被相应的`ENV_VAR`环境变量值取代。

### DataDog

VictoriaMetrics 支持接收 [DataDog agent](https://docs.datadoghq.com/agent/) 发送出的数据, [DogStatsD](https://docs.datadoghq.com/developers/dogstatsd/) 和 [DataDog Lambda Extension](https://docs.datadoghq.com/serverless/libraries_integrations/extension/)， 使用`/datadog/api/v2/series`『submit metrics』或使用`/datadog/api/beta/sketches`『sketches』。

#### 发送 metrics 到 VictoriaMetrics #

DataDog agent 支持通过环境变量`DD_DD_URL`配置发送地址，或者在配置文件的`dd_url`部分配置

![](https://docs.victoriametrics.com/README_sending_DD_metrics_to_VM.webp)


使用环境变量配置发送地址：

```sh
DD_DD_URL=http://victoriametrics:8428/datadog
```

在配置文件中配置发送地址，只需在配置文件中加入下面一行内容：

```yaml
dd_url: http://victoriametrics:8428/datadog
```

[vmagent]({{< relref "../components/vmagent.md" >}}) 组件也可以接收 DataDog metrics 数据格式。

#### 发送 metrics 到 DataDog 和 VictoriaMetrics

DataDog 允许通过环境变量`DD_ADDITIONAL_ENDPOINTS`添加额外的地址实现[数据双发](https://docs.datadoghq.com/agent/guide/dual-shipping/)，让它把 metrics 发送给其他额外的地址，也可以通过配置文件中的`additional_endpoints`配置项设置。

![](https://docs.victoriametrics.com/README_sending_DD_metrics_to_VM_and_DD.webp)

使用环境变量配置额外的发送地址：

```sh
DD_ADDITIONAL_ENDPOINTS='{\"http://victoriametrics:8428/datadog\": [\"apikey\"]}'
```

使用[配置文件](https://docs.datadoghq.com/agent/guide/agent-configuration-files)设置额外的发送地址：

```yaml
additional_endpoints:
  "http://victoriametrics:8428/datadog":
  - apikey
```

#### 使用 Serverless DataDog 插件发送 metrics

禁用日志能力(因为 VictoriaMetrics 不支持日志写入) ，且在`serverless.yaml`中自定义发送地址：

```yaml
custom:
  datadog:
    enableDDLogs: false             # Disabled not supported DD logs
    apiKey: fakekey                 # Set any key, otherwise plugin fails
provider:
  environment:
    DD_DD_URL: <<vm-url>>/datadog   # VictoriaMetrics endpoint for DataDog
```

#### 通过 cURL 发送

URL 地址是`/datadog/api/v2/series`

单机版：

```sh
echo '
{
  "series": [
    {
      "metric": "system.load.1",
      "type": 0,
      "points": [
        {
          "timestamp": 0,
          "value": 0.7
        }
      ],
      "resources": [
        {
          "name": "dummyhost",
          "type": "host"
        }
      ],
      "tags": ["environment:test"]
    }
  ]
}
' | curl -X POST -H 'Content-Type: application/json' --data-binary @- http://localhost:8428/datadog/api/v2/series
```


集群版：
```sh
echo '
{
  "series": [
    {
      "metric": "system.load.1",
      "type": 0,
      "points": [
        {
          "timestamp": 0,
          "value": 0.7
        }
      ],
      "resources": [
        {
          "name": "dummyhost",
          "type": "host"
        }
      ],
      "tags": ["environment:test"]
    }
  ]
}
' | curl -X POST -H 'Content-Type: application/json' --data-binary @- 'http://<vminsert>:8480/insert/0/datadog/api/v2/series'
```

#### 更多细节

VictoriaMetrics 会根据 DataDog 指标命名建议，自动对通过 DataDog 协议写入的数据进行指标名称转换。 如果您需要接受不经过转换的指标名称，则向 VictoriaMetrics 传递`-datadog.sanitizeMetricName=false`参数。 

通过在url中增加`extra_label=name=value`参数，可以向所有写入的时间序列数据添加额外 Label。 例如，`/datadog/api/v2/series?extra_label=foo=bar`将为所有写入的数据添加`{foo="bar"}`标签。 

DataDog agent 会将配置的Label发送到未注明的地址 - `/datadog/intake`。 VictoriaMetrics 尚不支持该接口。 这导致无法将配置的标记添加到发送到 VictoriaMetrics 的 DataDog agent 数据中。解决方法是在运行每个 DataDog agent 的同时运行一个 sidecar vmagent，该 agent 必须使用`DD_DD_URL=http://localhost:8429/datadog`环境变量运行。 必须通过`-remoteWrite.label`参数使用所需的标签配置 sidecar vmagent，并且必须将带有已添加标签的传入数据转发到通过 `-remoteWrite.url`参数指定的集中式 VictoriaMetrics。


### InfluxDB

#### 如何让 InfluxDB兼容的 agent 发送数据给 VictoriaMetrics（例如 [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/)）

使用`http://<victoriametrics-addr>:8428`地址代替 agent 配置中的 InfluxDB 地址。例如，把下面几行放到 telegraf 的配置中，那么它就会将数据发送给 VictoriaMetrics：

```toml
[[outputs.influxdb]]
  urls = ["http://<victoriametrics-addr>:8428"]
```

另一个办法是使用`-influxListenAddr`参数开启针对 InfluxDB Line Protocol 的 TCP/UDP 服务，这样就可以将 InfluxDB Line Protocol 的行数据流式的发送给这个 TCP/UDP 地址了。


VictoriaMetrics 对接收到的 InfluxDB 数据做了如下转换：

- 除非 InfluxDB 行中已经存在`db`label 内容，否则 url 中的`db`参数会被注入到数据 Label 中。`db`是用于表示数据库的默认 Label 名，可以通过`-influxDBLabel`参数修改`db`的 Label 名称。如果要实现严格的数据隔离，请阅读[多租户相关信息]({{< relref "../ops/cluster.md#tenant" >}})。
- Influx Field 名字会被追加上`{measurement}{separator}`前缀，作为 Metric 名称， 其中`{separator}`默认是下划线`_`。可以使用`-influxMeasurementFieldSeparator`参数自定义。如果`{measurement}`为空或者使用了`-influxSkipMeasurement`参数，则直接使用 InfluxDB 的 Field 名称作为 Metric 名称。 `-influxSkipSingleField`。
- Influx Field 值会被作为 Timeseries 的值。
- Influx Tags 会被作为 Prometheus Labels.
- 如果设置了`-usePromCompatibleNaming`参数，则所有的 Metric 名和 Label 名 都会被格式化成 Prometheus兼容的明明规则，并使用下划线`_`代替非法字符。例如如果 Metric 名或 Label 名是`foo.bar-baz/1`，则会被格式化成`foo_bar_baz_1`。

例如，下面是一行 InfluxDB 协议的数据：

```plain
foo,tag1=value1,tag2=value2 field1=12,field2=40
```

该行数据内容将会被转换为如下的 Prometheus 格式数据：

```plain
foo_field1{tag1="value1", tag2="value2"} 12
foo_field2{tag1="value1", tag2="value2"} 40
```

通过 curl 命令将 InfluxDB Line Protocol 格式数据写入到本地的 VictoriaMetrics 举例：

```sh
curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/write'
```

你可以使用`\n`在一个请求里发送多行数据。通过如下的命令可以将写入的数据导出：


```sh
curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"measurement_.*"}'
```

使用 `/api/v1/export` 接口查询数据，会返回如下内容：

```json
{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1560272508147]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1560272508147]}
```

注意 InfluxDB Line Protocol 期望的时间戳是纳秒级，而 VictoriaMetrics 是以毫秒的精度存储。系统允许使用秒、微妙或纳秒的精度写入数据，VictoriaMetrics 会自动转换成毫秒精度存储。

通过在url中增加`extra_label=name=value`参数，可以向所有写入的时间序列数据添加额外 Label。 例如，`/write?extra_label=foo=bar`将为所有写入的数据添加`{foo="bar"}`标签。 

一些 Telegraf 的插件如 fluentd, Juniper/open-nti 或 Juniper/jitmon 会发送`SHOW DATABASES`查询到`/query`来获取数据库名字列表，并期望返回结果中包含特定的数据库名。可以将逗号分割的多个数据库名作为`-influx.databaseNames`参数。

#### 发送 V2 版本

VictoriaMetrics 在`/influx/api/v2/write`和`/api/v2/write`接口上支持 InfluxDB v2 HTTP API 写入协议。

通过 curl 命令将 InfluxDB Line Protocol 格式数据写入到本地的 VictoriaMetrics 举例：

```sh
curl -d 'measurement,tag1=value1,tag2=value2 field1=123,field2=1.23' -X POST 'http://localhost:8428/api/v2/write'
```

使用 `/api/v1/export` 接口查询数据，会返回如下内容：

```json
{"metric":{"__name__":"measurement_field1","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1695902762311]}
{"metric":{"__name__":"measurement_field2","tag1":"value1","tag2":"value2"},"values":[1.23],"timestamps":[1695902762311]}
```

### Graphite

#### StatD

使用`-graphiteListenAddr`参数可以开启 Graphite 支持；比如下面的命令使 VictoriaMetrics 通过监听`2003`TCP/UDP端口 来接收 Graphite 数据。

```sh
/path/to/victoria-metrics-prod -graphiteListenAddr=:2003
```

将上面的地址配置到 Graphite 兼容的 agent 上。例如，在`StatD`的配置中设置`graphiteHost`配置项。

下面的命令是使用`nc`命令将数据以 Graphite 文本协议写入到本地的 VictoriaMetrics 中：

```sh
echo "foo.bar.baz;tag1=value1;tag2=value2 123 `date +%s`" | nc -N localhost 2003
```

使用`-graphite.sanitizeMetricName`参数让 VictoriaMetrics 将写入的 Graphite metrics 使用 Prometheus 命名规范进行一定的转换。当使用该参数时，数据的修改规则如下：

- 删除多余的点`.`符号，比如`metric..name` => `metric.name`
- 对于没有匹配`a-zA-Z0-9:_.`的字符，统一转换成下划线`_`
- VictoriaMetrics 将数据写入时间作为时序数据的时间

An arbitrary number of lines delimited by \n (aka newline char) can be sent in one go. After that the data may be read via /api/v1/export endpoint:

```sh
curl -G 'http://localhost:8428/api/v1/export' -d 'match=foo.bar.baz'
```
The /api/v1/export endpoint should return the following response:

```json
{"metric":{"__name__":"foo.bar.baz","tag1":"value1","tag2":"value2"},"values":[123],"timestamps":[1560277406000]}
```
Graphite relabeling can be used if the imported Graphite data is going to be queried via MetricsQL.

### 导入 Prometheus exposition 格式数据 {#exposition}

VictoriaMetrics 支持 Prometheus exposition 数据格式， OpenMetrics 格式以及 Pushgateway 格式数据写入。写入 URL 是`/api/v1/import/prometheus`。

例如，下面的命令就是将一行 Prometheus exposition 格式的数据写入 VictoriaMetrics：
```sh
curl -d 'foo{bar="baz"} 123' -X POST 'http://localhost:8428/api/v1/import/prometheus'
```
可使用下面的命令验证刚导入的数据：
```sh
curl -G 'http://localhost:8428/api/v1/export' -d 'match={__name__=~"foo"}'
```
上面的命令将返回如下内容：
```json
{"metric":{"__name__":"foo","bar":"baz"},"values":[123],"timestamps":[1594370496905]}
```

## 集群版

集群版和单机版在 API URL 上的主要区别，就是集群版在 URL Path 上对查询和写入都增加了前缀。并且集群版支持`/prometheus/api/v1`接口接收`jsonl`,`csv`,`native`和prometheus格式数据。

写入 API 的 URL 格式为:`http://<vminsert>:8480/insert/<accountID>/<suffix>`，这里：

- <accountID> 是一个32位整型数字，代表数据写入的控件（即租户）。它也可以设置为`accountID:projectID`，这里的projectID也是一个32位整型。如果projectID没有指定，则默认为0。更多内容请阅读[多租户]({{< relref "../ops/cluster.md#tenant" >}})，`<accountID>`也可以写成字符串`multitenant`，例如`http://<vminsert>:8480/insert/multitenant/<suffix>`，使用这种 URL 写入的数据，系统会从数据 Label 中寻找`vm_account_id`和`vm_project_id`信息，将 Label 值作为租户信息。更多内容请阅读[多租户]({{< relref "../ops/cluster.md#tenant" >}})

- <suffix> 可以是一下的内容：
  - `prometheus` and `prometheus/api/v1/write` - 处理 Prometheus Remote Write 数据
  - `prometheus/api/v1/import` - 处理从`api/v1/export`(vmselect组件提供)接口导出的数据，格式为 JSON
  - `prometheus/api/v1/import/native` - 处理从`api/v1/export/native`(vmselect组件提供)接口导出的数据
  - `prometheus/api/v1/import/csv` - 处理 CSV 数据
  - `prometheus/api/v1/import/prometheus` - 处理 Prometheus Text Exposition 格式或 OpenMetrics 格式数据，也可以处理 Pushgateway 组件推送出来的数据
  - `opentelemetry/v1/metrics` - 处理 OpenTelemetry 协议数据
  - `datadog/api/v1/series` - 处理 DataDog submit metrics 数据
  - `datadog/api/v2/series` - 处理 DataDog submit metrics 数据(v2)
  - `datadog/api/beta/sketches` - 处理 DataDog lambda 表达式写入的数据
  - `influx/write` and `influx/api/v2/write` - 处理 InfluxDB line protocol 数据 TCP 和 UDP 接收器默认是关闭的，需要使用`-influxListenAddr`参数打开
  - `newrelic/infra/v2/metrics/events/bulk` - 处理 NewRelic agent 写入的数据
  - `opentsdb/api/put` - 处理 OpenTSDB /api/put HTTP 请求，该处理器默认是关闭的，使用`-opentsdbHTTPListenAddr`参数开启