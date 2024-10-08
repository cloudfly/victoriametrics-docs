---
title: 集群版本
weight: 2
---

## 架构概览
VictoriaMetrics 集群版本由以下几个服务组成：

+ `vmstorage` - 存储原始数据，并返回在给定时间范围内针对给定 Label 筛选器查询的数据。
+ `vminsert` - 接受摄入的数据，并 根据对度量名称及其所有标签的一致散列，将数据分散到 `vmstorage` 节点中
+ `vmselect` - 通过从所有已配置的 `vmstorage` 节点获取所需数据来执行接收到的查询请求。

每项服务都可独立扩展，并可在最合适的硬件上运行。 `vmstorage` 节点之间互不相识，互不通信，也不共享任何数据。 这是一种[共享无架构](https://en.wikipedia.org/wiki/Shared-nothing_architecture) 。 它提高了集群的可用性，简化了集群维护和集群扩展。

## 多租户
VictoriaMetrics集群支持多个隔离的租户（即命名空间）。租户通过accountID或accountID:projectID进行标识，这些标识符被置于请求URL中。详情请参阅[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#url-format)。

关于VictoriaMetrics中租户的一些事实：

每个accountID和projectID均由一个任意的32位整数标识，范围为`[0..2^32)`。如果projectID缺失，则自动分配为0。预期其他关于租户的信息，如身份验证令牌、租户名称、限制、会计等，存储在一个独立的关系数据库中。该数据库必须由位于VictoriaMetrics集群前端的独立服务进行管理，例如[vmauth](https://docs.victoriametrics.com/vmauth.html)或[vmgateway](https://docs.victoriametrics.com/vmgateway.html)。如果您需要此类服务的协助，请联系我们。

当第一个数据点被写入给定的租户时，租户会被自动创建。

所有租户的数据均匀分布在可用的`vmstorage`节点之间。这保证了当不同租户拥有不同数量的数据和不同的查询负载时，`vmstorage`节点之间的负载也是均匀的。

数据库的性能和资源使用情况并不取决于租户的数量，而主要取决于所有租户中活跃时间序列的总数。如果一个时间序列在过去的一小时中至少接收了一个样本，或者在过去的一小时中被查询访问过，那么它就被认为是活跃的。

VictoriaMetrics不支持在单一请求中查询多个租户。

已注册租户的列表可以通过`http://<vmselect>:8481/admin/tenants` URL获取。请参阅[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#url-format)。

VictoriaMetrics通过指标公开了各种按租户划分的统计数据——请参阅[这些文档](https://docs.victoriametrics.com/PerTenantStatistic.html)。

也可以看下[通过 labels 实现多租户](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#multitenancy-via-labels)。

## 通过 labels 实现多租户
`vminsert`可以从多个租户通过一个特殊的[多租户](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#multitenancy)端点`http://vminsert:8480/insert/multitenant/<suffix>`接收数据，其中可以替换为从此列表中获取数据的任何受支持的`<suffix>`。在这种情况下，AccountID 和ProjectID是从传入样本的可选 `vm_account_id` 和 `vm_project_id` 标签中获取的。如果 vm_account_id 或 vm_project_id 标签缺失或无效，则相应的AccountID 或ProjectID 将设置为 0。在将样本转发到`vmstorage`之前，会自动从样本中删除这些Label。例如，如果将以下样本写入 `http://vminsert:8480/insert/multitenant/prometheus/api/v1/write`：


```plain
http_requests_total{path="/foo",vm_account_id="42"} 12
http_requests_total{path="/bar",vm_account_id="7",vm_project_id="9"} 34
```

然后`http_requests_total｛path=“/foo”｝12`将被存储在租户`accountID=42，projectID=0`中，而`http_requests_total{path=“/bar”｝34`将被存储到租户`accountID=7，projectID=9`中。

`vm_account_id`和`vm_project_id` labels 是在通过`-rebelConfig`命令行标志应用 [relabeling](https://docs.victoriametrics.com/relabeling.html) 集后提取的，因此可以在此阶段设置这些 label。

安全提示：建议将对多租户端点的访问限制为仅限可信源，因为不可信源可能会通过向任意租户写入不需要的样本来破坏每个租户的数据。

## 二进制
集群版本的编译二进制文件可在[发布页面](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)的 assets 部分中找到。另请参阅包含单词“集群”的档案。

集群版本的 Docker 镜像可在此处找到：

+ `vminsert` - [https://hub.docker.com/r/victoriametrics/vminsert/tags](https://hub.docker.com/r/victoriametrics/vminsert/tags)
+ `vmselect` - [https://hub.docker.com/r/victoriametrics/vmselect/tags](https://hub.docker.com/r/victoriametrics/vmselect/tags)
+ `vmstorage` - [https://hub.docker.com/r/victoriametrics/vmstorage/tags](https://hub.docker.com/r/victoriametrics/vmstorage/tags)

## 源码构建
集群版本的源代码可在[cluster分支](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/cluster)中获取。

### 生产环境构建
无需在主机系统上安装 Go，因为二进制文件是在 [Go 的官方 docker 容器](https://hub.docker.com/_/golang)内构建的。这允许可重现的构建。因此，[安装 docker](https://docs.docker.com/install/) 并运行以下命令：


```plain
make vminsert-prod vmselect-prod vmstorage-prod
```

生产二进制文件内置于静态链接二进制文件中。它们被放入带有 `-prod` 后缀的 `bin` 文件夹中：


```plain
$ make vminsert-prod vmselect-prod vmstorage-prod
$ ls -1 bin
vminsert-prod
vmselect-prod
vmstorage-prod
```

### 开发环境构建
1. [安装Go](https://golang.org/doc/install)，最低支持版本是 Go1.18。
2. 从[仓库根目录](https://github.com/VictoriaMetrics/VictoriaMetrics)运行 `make`。它应该构建 `vmstorage`、`vmselect` 和 `vminsert` 二进制文件并将它们放入 bin 文件夹中。

### 构建 docker 镜像
执行 `make package`命令，会在本地构建下面几个 docker 镜像：

+ `victoriametrics/vminsert:<PKG_TAG>`
+ `victoriametrics/vmselect:<PKG_TAG>`
+ `victoriametrics/vmstorage:<PKG_TAG>`

`<PKG_TAG>` 是根据[仓库中的源码](https://github.com/VictoriaMetrics/VictoriaMetrics)自动生产的 image tag。`<PKG_TAG>` 可以使用环境变量来指定，比如：`PKG_TAG=foobar make package`.

默认情况下，为了提高可调试性，image 是在 [alpine image](https://hub.docker.com/_/scratch) 之上构建的。可以通过 <ROOT_IMAGE> 环境变量设置，在任何其他基础镜像之上构建镜像。例如，以下命令在[临时镜像](https://hub.docker.com/_/scratch)之上构建镜像：


```plain
ROOT_IMAGE=scratch make package
```

## 运维 {#operation}
## 部署集群
一个集群至少包含下面几项：

+ 一个 `vmstorage` 节点，需要指定 `-retentionPeriod` 和 `-storageDataPath` 参数
+ 一个 `vminsert` 节点，需要指定 `-storageNode=<vmstorage_host>`
+ 一个 `vmselect` 节点，需要指定 `-storageNode=<vmstorage_host>`

建议每个服务至少运行两个实例，以实现高可用性。在这种情况下，当单个节点暂时不可用时，群集仍可继续工作，其余节点可处理增加的工作量。在底层硬件损坏、软件升级、迁移或其他维护任务期间，节点可能会暂时不可用。

最好运行许多小型 vmstorage 节点而不是少数大型 vmstorage 节点，因为当某些 vmstorage 节点暂时不可用时，这可以减少剩余 vmstorage 节点上的工作负载增加。

必须在 vminsert 和 vmselect 节点前放置一个 http 负载均衡器，例如 [vmauth](https://docs.victoriametrics.com/vmauth.html) 或 nginx。它必须根据 [url 格式](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#url-format)包含以下路由配置：

+ 带有 `/insert` 前缀的请求必须被路由到 vminsert 实例的 8480 端口数。
+ 带有 `/select` 前缀的请求必须被路由到 vmselect 实例的 8481 端口数。

端口可以通过在相应节点上通过 `-httpListenAddr` 参数来设定。

建议为集群配置上[监控](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#monitoring)。

下面的工具可以简化集群部署：

+ [An example docker-compose config for VictoriaMetrics cluster](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/deployment/docker/docker-compose-cluster.yml)
+ [Helm charts for VictoriaMetrics](https://github.com/VictoriaMetrics/helm-charts)
+ [Kubernetes operator for VictoriaMetrics](https://github.com/VictoriaMetrics/operator)

可以在单个主机上手动设置一个玩具集群。在这种情况下，每个集群组件 - vminsert、vmselect 和 vmstorage - 必须使用 `-httpListenAddr` 命令行参数指定不同的端口。此参数指定用于接受用于[监控](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#monitoring)和[Profiling](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#profiling) http 请求的 http 地址。`vmstorage` 节点必须具有以下附加命令行参数的不同值，以防止资源使用冲突：

+ `-storageDataPath` - 每个 `vmstorage` 实例都不行有一个专用的数据存储路径。
+ `-vminsertAddr` - 每个 `vmstorage` 实例必须监听一个 tcp 地址，用来接受 vminsert 发送过来的数据。
+ `-vmselectAddr` - 每个 `vmstorage` 实例必须监听一个 tcp 地址，用来处理 vmselect 发送过来的查询请求。

### 环境变量
所有的 VictoriaMetrics 组件都可以在命令行参数中使用`%{ENV_VAR}`语法来引用环境变量。比如，如果 VictoriaMetrics 启动的时候存在环境变量`METRICS_AUTH_KEY=top-secret` ，那么`-metricsAuthKey=%{METRICS_AUTH_KEY}` 参数会自动转换成 `-metricsAuthKey=top-secret`。这个转换是 VictoriaMetrics 内部自己完成的。

VictoriaMetrics 在启动的时候会递归式的对`%{ENV_VAR}` 进行环境变量引用转换。比如，当存在环境变量 `BAR=a%{BAZ}` 和 `BAZ=bc`时，`FOO=%{BAR}` 环境变量会被转换为 `FOO=abc` 。

所有的 VictoriaMetrics 组件都支持通过上述的环境变量方式来设置参数，前提是：

+ 必须使用`-envflag.enable` 参数开启该特性。
+ 命令行参数中的 `.` 必须用下划线`_`替换 (比如 `-insert.maxQueueDuration <duration>` 对应的环境变量是 `insert_maxQueueDuration=<duration>`)。
+ 对于可重复的指定的参数，可用逗号`,`分隔符进行链接。 (比如 `-storageNode <nodeA> -storageNode <nodeB>` 对应的环境变量是 `storageNode=<nodeA>,<nodeB>`)。
+ 可以使用 `-envflag.prefix` 参数来指定环境变量前缀，例如使用了 `-envflag.prefix=VM_`参数，那么环境变量名就都必须以 `VM_` 开头。

## vmstorage 自动发现
只有企业版支持`vminsert `和` vmselect `对` vmstorage`实例自动服务发现，开源版的话需要进行二次开发。

VictoriaMetrics 的代码质量很高，所以二次开发也比较简单。只需要参考[netstorage.Init](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/cluster/app/vminsert/netstorage/netstorage.go#L507)实现即可，仅有 2 行代码。这里给出一个代码实现参考：


```plain
// ResetStorageNodes initializing new storageNodes by using new addrs, and replace the old global storageNodes
func ResetStorageNodes(addrs []string, hashSeed uint64) {
	if len(addrs) == 0 {
		return
	}
	prevSnb := getStorageNodesBucket()
	snb := initStorageNodes(addrs, hashSeed)
	setStorageNodesBucket(snb)
	if prevSnb != nil {
		go func() {
			logger.Infof("Storage nodes updated, stopping previous storage nodes")
			mustStopStorageNodes(prevSnb)
			logger.Infof("Previous storage nodes already stopped")
		}()
	}
}
```

自己实现发现实例列表的库，在库里面调用该`ResetStorageNodes`方法即可。

## 安全
一般的安全建议：

+ 所有 VictoriaMetrics 集群组件都必须在受保护的私有网络中运行，并且不能被互联网等不受信任的网络直接访问。
+ 外部客户端必须通过身份验证代理（例如 [vmauth](https://docs.victoriametrics.com/vmauth.html) 或 [vmgateway](https://docs.victoriametrics.com/vmgateway.html)）访问 vminsert 和 vmselect。
+ 为了保护身份验证令牌不被窃听，身份验证代理必须仅通过 https 接受来自不受信任网络的身份验证令牌。
+ 建议对不同的[租户](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#multitenancy)使用不同的身份验证令牌，以减少某些租户的身份验证令牌被泄露时造成的潜在损害。
+ 在 `vminsert` 和 `vmselect` 之前配置身份验证代理时，最好使用允许的 API 接口白名单，同时禁止访问其他接口。这可以最大限度地减少攻击面。

也可以参考 [security recommendation for single-node VictoriaMetrics](https://docs.victoriametrics.com/#security) 和 [the general security page at VictoriaMetrics website](https://victoriametrics.com/security/).

## 监控
所有集群组件均在 `-httpListenAddr` 命令行参数中设置的 TCP 端口上的 `/metrics` 页面上以 Prometheus 兼容格式公开各种指标。默认情况下，使用以下 TCP 端口：

+ `vminsert` - 8480
+ `vmselect` - 8481
+ `vmstorage` - 8482

建议使用 [vmagent](https://docs.victoriametrics.com/vmagent.html) 或 Prometheus 以从所有集群组件中抓取 `/metrics` 页面，这样就可以使用 VictoriaMetrics 集群的[官方 Grafana 大盘](https://grafana.com/grafana/dashboards/11176-victoriametrics-cluster/)或 [VictoriaMetrics 集群大盘](https://grafana.com/grafana/dashboards/11831)来监控和分析它们。这些仪表板上的图表包含有用的提示 - 将鼠标悬停在每个图表左上角的 `i` 图标上即可阅读。

建议通过[此配置](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/cluster/deployment/docker/alerts.yml)在 [vmalert](https://docs.victoriametrics.com/vmalert.html) 或 Prometheus 中设置告警。更多详细信息请参阅文章 [VictoriaMetrics 监控](https://victoriametrics.com/blog/victoriametrics-monitoring/)。 基数限制。

## 基数限制
`vmstorage` 实例可以通过下面的命令行来限制所有租户总共 series 的数量

+ `-storage.maxHourlySeries` 限制最近1小时的[活跃时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的数量。
+ `-storage.maxDailySeries` 限制最近一天的[活跃时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的数量。这个限制可以用于限制天级别的 [time series churn rate](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate).

请注意，这些限制是针对集群中的每个 vmstorage 实例的。因此，如果集群有 `N` 个 `vmstorage` 节点，则整个集群级限制将比每个 `vmstorage` 限制大 `N` 倍。

关于更多的基数限制可以看[这些文档](https://docs.victoriametrics.com/#cardinality-limiter)。 

## 问题排查
请看[问题排查文档](https://docs.victoriametrics.com/Troubleshooting.html)。

## 只读模式
当 `-storageDataPath` 指向的目录包含的可用空间少于 `-storage.minFreeDiskSpaceBytes` 时，vmstorage 节点会自动切换到只读模式。`vminsert` 节点停止向此类节点发送数据，并开始将数据重新路由到剩余的 vmstorage 节点。

当 `vmstorage` 进入只读模式时，它会将 http://vmstorage:8482/metrics 上的 `vm_storage_is_read_only` 指标设置为 `1`。当 `vmstorage` 未处于只读模式时，该指标值为 `0`。

## API接口
集群版本和[单机版](https://www.victoriametrics.com.cn/victoriametrics/dan-ji-ban-ben)的API接口主要区别是数据的读取和写入是由独立组件完成的，而且也有了租户的支持。集群版本也支持`/prometheus/api/v1`来接收 `jsonl`, `csv`, `native` 和 `prometheus`数据格式，而不仅仅是`prometheus`数据格式。可以在[这里](https://docs.victoriametrics.com/url-examples.html)查看VictoriaMetrics的API的使用范例。

+ 用于数据写入的 URLs 是：`http://<vminsert>:8480/insert/<accountID>/<suffix>`，其中：
+ `<accountID>` 是一个任意的32位数字，用来表示数据写入的空间（即租户）。也可以设置成`accountID:projectID`格式，其中 `projectID` 也是一个任意的32位数字。如果 `projectID` 没有指定,则默认是`0`。更多信息可以看[多租户文档](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#multitenancy)。 这里的`<accountID>` 可以使用字符串 `multitenant` ， 比如 `http://<vminsert>:8480/insert/multitenant/<suffix>`，该 URL 接受到的数据会将数据的 `vm_account_id` 和 `vm_project_id` label 视为租户信息。更多信息请看[通过label实现多租户](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#multitenancy-via-labels)。
+ `<suffix>` 可以是以下这些内容：
    - `prometheus` 和 `prometheus/api/v1/write` - 用来写入 [Prometheus Remote Write](https://prometheus.io/docs/prometheus/latest/configuration/configuration/#remote_write) 数据协议的接口。
    - `prometheus/api/v1/import` - 用来导入通过`vmselect`的 `api/v1/export` 接口导出来的数据（见下文）, 是 JSON line 的格式.
    - `prometheus/api/v1/import/native` - 用来导入通过vmselect的`api/v1/export/native` 接口导出的数据（见下文）。
    - `prometheus/api/v1/import/csv` - 用来导入 CSV 数据。详细信息见[文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-csv-data)。
    - `prometheus/api/v1/import/prometheus` - 用来导入 [Prometheus text exposition](https://github.com/prometheus/docs/blob/master/content/docs/instrumenting/exposition_formats.md#text-based-format) 或 [OpenMetrics](https://github.com/OpenObservability/OpenMetrics/blob/master/specification/OpenMetrics.md)格式的数据。该接口也支持 [Pushgateway 协议](https://github.com/prometheus/pushgateway#url)。 更多信息看[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-data-in-prometheus-exposition-format)。
    - `datadog/api/v1/series` - 用来写入 [DataDog submit metrics](https://docs.datadoghq.com/api/latest/metrics/#submit-metrics)接口。 更多信息见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-datadog-agent)。
    - `influx/write` and `influx/api/v2/write` - 用来写入 [InfluxDB line protocol](https://docs.influxdata.com/influxdb/v1.7/write_protocols/line_protocol_tutorial/)的数据，更多信息见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-send-data-from-influxdb-compatible-agents-such-as-telegraf)。
    - `opentsdb/api/put` - 用来处理 [OpenTSDB HTTP /api/put 请求](http://opentsdb.net/docs/build/html/api_http/put.html)。这个接口默认是关闭的。他是通过一个独立的 TCP 地址暴露的，改地址可通过`-opentsdbHTTPListenAddr` 命令行参数指定。更多信息见[这些文档](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#sending-opentsdb-data-via-http-apiput-requests)。
+ [Prometheus 查询 API](https://prometheus.io/docs/prometheus/latest/querying/api/): `http://<vmselect>:8481/select/<accountID>/prometheus/<suffix>`, 其中:
    - `<accountID>` 是一个任意32位数字，用来标识查询的空间（即租户）。
    - `<suffix>` 可以是一下的内容：
        * `api/v1/query` - 执行 [PromQL instant](https://docs.victoriametrics.com/keyConcepts.html#instant-query).
        * `api/v1/query_range` - 执行 [PromQL range 查询](https://docs.victoriametrics.com/keyConcepts.html#range-query)。
        * `api/v1/series` - 执行 [series 查询](https://prometheus.io/docs/prometheus/latest/querying/api/#finding-series-by-label-matchers)。
        * `api/v1/labels` - 返回 [label 名称列表](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names)。
        * `api/v1/label/<label_name>/values` - 返回指定 `<label_name>` 的所有值，参考[这个 API](https://prometheus.io/docs/prometheus/latest/querying/api/#querying-label-values).
        * `federate` - 返回 [federated metrics](https://prometheus.io/docs/prometheus/latest/federation/).
        * `api/v1/export` - 导出 JSON line 格式的原始数据，更多信息看[这篇文章](https://medium.com/@valyala/analyzing-prometheus-data-with-external-tools-5f3e5e147639)。
        * `api/v1/export/native` - 导出原生二进制格式的原始数据，该数据可以通过另一个接口`api/v1/import/native`导入到 VictoriaMetrics (见上文).
        * `api/v1/export/csv` - 导出 CSV 格式原始数据。它可以使用另外一个接口 `api/v1/import/csv` 导入到 VictoriaMetrics（见上文）。
        * `api/v1/series/count` - 返回 series 的总数。
        * `api/v1/status/tsdb` - 返回时序数据的统计信息。更多详细信息见[这些文档](https://docs.victoriametrics.com/#tsdb-stats)。
        * `api/v1/status/active_queries` - 返回当前活跃的查询请求。逐一每个 `vmselect` 实例都有独立的活跃查询列表。
        * `api/v1/status/top_queries` - 返回执行频率最高以及查询耗时最长的查询列表。
        * `metric-relabel-debug` - 用于对 [relabeling 规则](https://docs.victoriametrics.com/relabeling.html) Debug。
+ [Graphite Metrics API](https://graphite-api.readthedocs.io/en/latest/api.html#the-metrics-api)：`http://<vmselect>:8481/select/<accountID>/graphite/<suffix>`, 其中:
    - `<accountID>`
    - 是一个任意32位数字，用来标识查询的空间（即租户）。
    - `<suffix>` 可以是一下的内容：
        * `render` - 实现 Graphite Render API. 看 [these docs](https://graphite.readthedocs.io/en/stable/render_api.html).
        * `metrics/find` - 搜索 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-find).
        * `metrics/expand` - 扩展 Graphite metrics. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-expand).
        * `metrics/index.json` - returns 所有的 names. See [these docs](https://graphite-api.readthedocs.io/en/latest/api.html#metrics-index-json).
        * `tags/tagSeries` - 注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).
        * `tags/tagMultiSeries` - 批量注册 time series. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#adding-series-to-the-tagdb).
        * `tags` - 返回 tag 名称列表. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
        * `tags/<tag_name>` - 返回指定 `<tag_name>`的值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
        * `tags/findSeries` - 返回匹配`expr`的 series，[these docs](https://graphite.readthedocs.io/en/stable/tags.html#exploring-tags).
        * `tags/autoComplete/tags` - 返回匹配 `tagPrefix` 和/或 `expr`的tag名称列表。 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
        * `tags/autoComplete/values` - 返回匹配 `valuePrefix` 和/或 `expr` tag值列表 See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#auto-complete-support).
        * `tags/delSeries` - deletes series matching the given `path`. See [these docs](https://graphite.readthedocs.io/en/stable/tags.html#removing-series-from-the-tagdb).
+ 基础的 Web UI: `http://<vmselect>:8481/select/<accountID>/vmui/`.
+ 统计所有租户的查询：`http://<vmselect>:8481/api/v1/status/top_queries`。它会列出请求最频繁，以及执行时间最长的查询列表。
+ 删除时间序列：`http://<vmselect>:8481/delete/<accountID>/prometheus/api/v1/admin/tsdb/delete_series?match[]=<timeseries_selector_for_delete>`。 请注意，`delete_series` 处理程序应仅在特殊情况下使用，例如删除意外提取的错误时间序列。它不应定期使用，因为它会带来额外的系统开销。
+ 列出在给定时间范围内已提取数据的租户： `http://<vmselect>:8481/admin/tenants?start=...&end=...`。`start` 和 `end` 参数是可选的。默认返回 VictoriaMetrics 集群中至少包含一条数据的租户列表。
+ [vmalerts](https://docs.victoriametrics.com/vmalert.html) UI 界面： `http://<vmselect>:8481/select/<accountID>/prometheus/vmalert/`。这个 URL works only 只有在指定了 `-vmalert.proxyURL` 参数时才有效。关于 vmalert 的跟多内容[参考这里](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#vmalert)。 
+ `vmstorage` 在 8482 端口上提供了如下接口：
    - `/internal/force_merge` - 强制启动 vmstorage 实例的[数据合并压缩](https://docs.victoriametrics.com/#forced-merge)。
    - `/snapshot/create` - 创建[实例快照](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)，可用于后台备份。快照在`<storageDataPath>/snapshots` 文件夹中创建，其中`<storageDataPath>`是通过相应的命令行参数指定。
    - `/snapshot/list` - 列出可用的快照。
    - `/snapshot/delete?snapshot=<id>` - 删除给定的快照。
    - `/snapshot/delete_all` - 删除所有快照。

快照可以在每个 `vmstorage` 节点上独立创建。无需在 `vmstorage` 节点之间同步快照的创建。

## 集群扩缩容
集群的性能和容量有两种提升方式：

+ 为先有的实例节点增加计算资源（CPU，内存，磁盘IO，磁盘空间，网络带宽），即垂直扩容。
+ 为集群增加更多的实例节点，即水平扩容。

一些扩容建议：

+ 向现有 `vmselect` 节点添加更多 CPU 和 RAM 可提高重度查询的性能，这些查询会处理大量时间序列和大量原始样本。请[参阅本文](https://valyala.medium.com/how-to-optimize-promql-and-metricsql-queries-85a1b75bf986)，了解如何检测和优化重度查询。
+ 添加更多 `vmstorage` 节点以增加集群可以处理的[活动时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的数量。这还会提高[高流失率](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)时间序列的查询性能。集群稳定性也会随着 `vmstorage` 节点数量的增加而提高，因为当某些 vmstorage 节点不可用时，活动 `vmstorage` 节点需要处理的额外工作负载较少。
+ 向现有 `vmstorage` 节点添加更多 CPU 和 RAM 会增加集群可以处理的[活动时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的数量。与向现有 `vmstorage` 节点添加更多 CPU 和 RAM 相比，添加更多 `vmstorage` 节点是更好的选择，因为 `vmstorage` 节点数量越多，集群稳定性就越高，并且会提高[高流失率](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)时间序列的查询性能。
+ 添加更多 `vminsert` 节点会增加最大可能的数据提取速度，因为提取的数据可能会在更多数量的 `vminsert` 节点之间分配。
+ 添加更多 `vmselect` 节点会增加最大可能的查询率，因为传入的并发请求可能会在更多 `vmselect` 节点之间分配。

新增 `vmstorage` 节点的步骤：

1. 启动具有与集群中现有节点相同的 `-retentionPeriod` 的新 `vmstorage` 节点。
2. 平滑启动 vmselect 节点，并在`-storageNode` 参数中把 `<new_vmstorage_host>`加上。
3. 平滑启动 vminsert 节点，并在`-storageNode` 参数中把 `<new_vmstorage_host>`加上。

## 升级集群节点
所有节点类型 - `vminsert`、`vmselect` 和 `vmstorage` - 都可以通过启停进行更新。向相应进程发送 `SIGINT` 信号，等待其退出，然后使用新配置启动新版本。 

存在以下集群更新/升级方法：

### 无停机策略
使用更新的配置/升级的二进制文件逐个重新启动集群中的每个节点。 

建议按以下顺序重新启动节点：

1. 重启 `vmstorage` nodes.
2. 重启 `vminsert` nodes.
3. 重启 `vmselect` nodes.

如果满足以下条件，此策略允许在不停机的情况下升级集群：

+ 集群至少有两个及以上实例（每种类型都有 `vminsert`、`vmselect` 和 `vmstorage`），因此当单个节点在重启期间暂时不可用时，其它实例可以继续接受新数据并处理传入请求。有关详细信息，请参阅[集群可用性](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#cluster-availability)文档。
+ 当任何类型的单个节点（`vminsert`、`vmselect` 或 `vmstorage`）在重启期间暂时不可用时，集群具有足够的计算资源（CPU、RAM、网络带宽、磁盘 IO）来处理当前工作负载。
+ 更新后的的二进制文件与集群中的其余组件兼容。请参阅 [CHANGELOG](https://docs.victoriametrics.com/CHANGELOG.html) 了解不同版本之间的兼容性说明。 

只要有一个条件不满足，则滚动重启可能会导致在升级期间集群不可用。在这种情况下，建议采用以下策略。

### 最短停机策略
1. 并发停止所有的 `vminsert` 和 `vmselect` 实例。
2. 并发重启所有的`vmstorage` 实例。
3. 并发重启所有的`vminsert` 和 `vmselect` 实例。

执行上述步骤时，集群无法进行数据提取和查询。通过在上述每个步骤中并行重启集群节点，可以最大限度地减少停机时间。与无停机策略相比，最短停机时间策略具有以下优势：

+ 当以前的版本与新版本不兼容时，它允许以最小的中断完成升级。
+ 当集群没有足够的计算资源（CPU、RAM、磁盘 IO、网络带宽）进行滚动升级时，它允许以最小的中断完成版本升级。 
+ 对于具有大量节点的集群或具有大量 vmstorage 节点的集群，它允许最短升级的持续时间，因为它需要很长时间才能平滑重启。

## 集群可用性
VictoriaMetrics 集群架构优先考虑可用性而不是数据一致性。这意味着，如果集群的某些组件暂时不可用，集群仍可用于数据提取和数据查询。 

如果满足以下条件，VictoriaMetrics 集群将保持可用： 

+ HTTP 负载平衡器必须停止将请求路由到不可用的 vminsert 和 vmselect 节点（[vmauth](https://docs.victoriametrics.com/vmauth.html) 停止将请求路由到不可用的节点）。 
+ 集群中必须至少有一个 vminsert 节点可用于处理数据提取工作负载。其余可用的的 vminsert 节点必须具有足够的计算能力（CPU、RAM、网络带宽）来处理当前的数据写入工作负载。如果其余可用的 vminsert 节点没有足够的资源来处理数据提取工作负载，则数据提取期间可能会出现任意延迟。有关更多详细信息，请参阅[容量规划](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#capacity-planning)和[集群扩缩容](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#cluster-resizing-and-scalability)文档。 
+ 集群中必须至少有一个 vmselect 节点可用于处理查询工作负载。其余活动的 vmselect 节点必须具有足够的计算能力（CPU、RAM、网络带宽、磁盘 IO）来处理当前的查询工作负载。如果剩余的活动 vmselect 节点没有足够的资源来处理查询工作负载，则在查询处理期间可能会发生任意故障和延迟。有关更多详细信息，请参阅[容量规划](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#capacity-planning)和[集群扩缩容](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#cluster-resizing-and-scalability)文档。 
+ 集群中必须至少有一个 vmstorage 节点可用，以接受新提取的数据和处理传入的查询。剩余的活动 vmstorage 节点必须具有足够的计算能力（CPU、RAM、网络带宽、磁盘 IO、可用磁盘空间）来处理当前工作负载。如果剩余的活动 vmstorage 节点没有足够的资源来处理查询工作负载，则在数据提取和查询处理期间可能会发生任意故障和延迟。有关更多详细信息，请参阅[容量规划](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#capacity-planning)和[集群扩缩容](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#cluster-resizing-and-scalability)文档。 

当某些 vmstorage 节点不可用时，集群的工作方式如下： 

+ vminsert 将新写入的数据从不可用的 vmstorage 节点重新路由到剩余的健康 vmstorage 节点。如果健康的 vmstorage 节点具有足够的 CPU、RAM、磁盘 IO 和网络带宽来处理新增加的数据量，就可确保新写入的数据得以正确保存。vminsert 会在健康的 vmstorage 节点之间均匀分布额外的数据，以便均匀分布这些节点上增加的负载。
+ 只要有一个 vmstorage 节点可用，vmselect 将继续提供查询。它会将其余健康 vmstorage 节点提供的查询的响应标记为部分响应，因为此类响应可能会丢失存储在暂时不可用的 vmstorage 节点上的历史数据。每个部分 JSON 响应都包含`“isPartial”：true` 选项。如果您更喜欢一致性而不是可用性，请使用 `-search.denyPartialResponse` 命令行参数运行 vmselect 节点。在这种情况下，只要有一个 vmstorage 节点不可用，vmselect 将返回错误。另一个选项是在vmselect的查询请求中加上`deny_partial_response=1` 参数。

vmselect 还接受 `-replicationFactor=N` 命令行参数。此参数表示 vmselect 在查询期间如果少于 `-replicationFactor` 个 vmstorage 节点不可用则返回完整响应，因为它假定剩余的 vmstorage 节点包含完整数据。有关详细信息，请参阅[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#replication-and-data-safety)。 

vmselect 不会为返回原始数据点的 API 处理程序提供部分响应 - `/api/v1/export*`[接口](https://docs.victoriametrics.com/#how-to-export-time-series)，因为用户通常希望这些数据始终是完整的。 

数据副本可用于提高存储耐用性。有关详细信息，请参阅[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#replication-and-data-safety)。

## 容量规划 {#capacity}
根据我们的[案例研究](https://docs.victoriametrics.com/CaseStudies.html)，与竞争解决方案（Prometheus、Thanos、Cortex、TimescaleDB、InfluxDB、QuestDB、M3DB）相比，VictoriaMetrics 在生产工作负载上使用的 CPU、RAM 和存储空间更少。 

每种节点类型（`vminsert`、`vmselect` 和 `vmstorage`）都可以在最合适的硬件上运行。集群容量随可用资源线性扩展。每种节点类型所需的 CPU 和 RAM 数量高度依赖于工作负载 - [活动时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的数量、[序列流失率](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)、查询类型、查询 qps 等。建议为您的生产工作负载设置一个测试 VictoriaMetrics 集群，并迭代扩展每个节点的资源和每个节点类型的节点数量，直到集群稳定下来。建议为[集群设置监控](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#monitoring)。它有助于确定集群设置中的瓶颈。还建议遵循[故障排除](https://docs.victoriametrics.com/#troubleshooting)文档。 

给定保留期所需的存储空间（保留期通过 vmstorage 上的 `-retentionPeriod` 命令行标志设置）可以根据测试运行中的磁盘空间使用情况推断出来。例如，如果在生产工作负载上进行一天的测试运行后存储空间使用量为 10GB，那么在 `-retentionPeriod=100d`（100 天保留期）的情况下，至少需要 `10GB*100=1TB` 的磁盘空间。可以使用 VictoriaMetrics 集群的[官方 Grafana 大盘](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#monitoring)监控存储空间使用情况。

建议保留以下数量的备用资源：

+ 所有节点类型均有 50% 的可用 RAM，用于降低工作负载暂时激增期间出现 OOM（内存不足）崩溃和速度减速的概率。
+ 所有节点类型均有 50% 的备用 CPU，以降低工作负载临时激增期间出现速度变慢的可能性。
+ vmstorage 节点的 `-storageDataPath` 命令行参数指向的目录中至少有 20% 的可用存储空间。另请参阅 vmstorage 的 `-storage.minFreeDiskSpaceBytes` 命令行[参数描述](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#list-of-command-line-flags-for-vmstorage)。

VictoriaMetrics 集群的一些容量规划技巧：

+ [多副本](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#replication-and-data-safety)可将集群所需的资源量增加多达 `N` 倍，其中 `N` 是副本数。这是因为 `vminsert` 将每个摄取样本的 N 个副本存储在不同的 `vmstorage` 节点上。查询期间，`vmselect` 会对这些副本进行重复数据删除。数据持久性最具成本和性能的解决方案是依赖高可用磁盘（例如 [Google Compute 持久磁盘](https://cloud.google.com/compute/docs/disks#pdspecs)），而不是使用 [VictoriaMetrics 级别的复制机制](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#replication-and-data-safety)。
+ 建议构建一个由众多小型 vmstorage 节点组成的集群，而非少数大型 vmstorage 节点。这样，在进行维护操作（如升级、配置更改或迁移）时，若部分 vmstorage 节点临时离线，集群更有可能保持高可用性和稳定性。举例来说，若一个集群拥有10个vmstorage节点，其中一个节点临时不可用，其余9个节点的负载将增加约11%（即1/9）。而如果集群仅由3个vmstorage节点构成，单个节点离线时，其余两个节点的负载将激增50%（即1/2）。在这种情况下，剩余节点可能无法承受额外的工作负载，导致集群过载，进而影响可用性和稳定性。
+ 增加每个vmstorage节点的RAM和CPU资源，或者添加新的vmstorage节点，可以提高集群对[活跃时间序列](https://docs.victoriametrics.com/FAQ.html#what-is-an-active-time-series)的处理能力。
+ 提高每个vmselect节点的CPU资源可以降低查询延迟，因为每个传入查询都由单个vmselect节点处理。vmselect节点的可用CPU核心数越多，其处理查询中涉及的时间序列的性能就越好。
+ 如果集群需要高速处理传入查询，可以通过添加更多vmselect节点来提高其处理能力，这样传入查询就可以分散到更多的vmselect节点上。
+ 默认情况下，vminsert会压缩发送给vmstorage的数据，以减少网络带宽使用。压缩过程会消耗vminsert节点额外的CPU资源。如果vminsert节点的CPU资源有限，可以通过在vminsert节点上传递`-rpc.disableCompression`命令行标志来禁用压缩。
+ 默认情况下，vmstorage在查询期间会压缩发送给vmselect的数据，以减少网络带宽使用。压缩过程会消耗vmstorage节点额外的CPU资源。如果vmstorage节点的CPU资源有限，可以通过在vmstorage节点上传递`-rpc.disableCompression`命令行参数来禁用压缩。

也可以参阅[资源使用限制文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#resource-usage-limits)。

## 资源使用限制
默认情况下，VictoriaMetrics 的集群组件会根据典型工作负载的最佳资源使用情况进行调整。某些工作负载可能需要细粒度的资源使用限制。在这种情况下，以下命令行参数可能会有用：

+ `-memory.allowedPercent` 和 `-memory.allowedBytes` 限制所有的 VictoriaMetrics 集群组件里的各种内部 cache 会使用的内存用量 —— `vminsert`, `vmselect` 和 `vmstorage`。请注意，VictoriaMetrics 组件可能会占用更多内存，因为这些参数并不限制其他地方消耗的内存，比如可能是查询请求消耗的。
+ `-search.maxMemoryPerQuery` 限制 vmselect 实例执行一次查询请求所使用的内存总量。申请超限的内存会被拒绝。查询大量时间序列的重查询，可能会超查询内存限制一点点。并发查询的内存总限制差不多等于`-search.maxMemoryPerQuery` 和 `-search.maxConcurrentRequests` 的乘机。
+ `vmselect`组件的`-search.maxUniqueTimeseries` 参数限制了单词查询能够查询并计算多少个独立时间序列。`vmselect` 会将该限制参数传递给 `vmstorage` 组件，`vmstorage` 在内存中记录每个查询请求检索到的时间序列的元信息，并消耗一定的 CPU 来处理检索到的时间序列。这意味着在 `vmstorage` 中，单个查询可使用的最大内存使用量和 CPU 使用量与 `-search.maxUniqueTimeseries` 成比例。
+ `vmselect`的`-search.maxQueryDuration` 参数限制了一个查询的执行时间。如果一个查询耗时超出了指定的限制，就会被取消执行。这可以使`vmselect` 和 `vmstorage` 遇到非预期的重查询时，避免 CPU 和 内存的重度消耗。
+ `vmselect`和`vmstorage`的`-search.maxConcurrentRequests` 参数限制单个`vmselect`和`vmstorage`实例可以同时执行多少个查询。更大的并发数通常意味着需要消耗更多的内存。比如，如果一个查询在执行期间需要额外消耗 100MiB 的内存，那么100个并行的查询就需要`100 * 100 MiB = 10 GiB`的额外内存。所以最好限制一下请求并发数，这样会把超出并发限制的请求挂起排队。`vmselect`和`vmstorage`同时提供了`-search.maxQueueDuration`命令行参数来限制请求排队的最长时间。同时也看下`vmselect`的`-search.maxMemoryPerQuery`参数。
+ `vmselect`和`vmstorage`的`-search.maxQueueDuration` 限制查询因超出并发数限制而挂起等待的最长时间。上面提到了`-search.maxConcurrentRequests`参数指定了允许的最大并发数量。
+ `vmselect`的`-search.maxSamplesPerSeries` 限制了对于一个时间序列能够处理的最大原始样本值的数量。在执行查询时，`vmselect`会顺序第处理每个检索到的时间序列中的原始样本值。它将每个时间序列的指定时间范围内的原始样本解压到内存，然后对齐执行[rollup函数](https://docs.victoriametrics.com/MetricsQL.html#rollup-functions)。`-search.maxSamplesPerSeries` .可以限制内存用量，以免vmselect处理的`start-end`时间范围内每个时间序列都包含上一条原始样本数据。
+ `vmselect`的`-search.maxSamplesPerQuery`限制一个查询最大处理的原始样本数。可以限制 `vmselect`遇到重查询时的CPU用量。
+ `-search.maxPointsPerTimeseries`限制了[范围查询(query range)](https://docs.victoriametrics.com/keyConcepts.html#range-query)中每个时间序列最终返回的最多数据点数。
+ `-search.maxPointsSubqueryPerTimeseries` 限制了每个[子查询](https://docs.victoriametrics.com/MetricsQL.html#subqueries)执行时所产生的最大数据点数。
+ `-search.maxSeriesPerAggrFunc` 限制一次查询由[MetricsQL聚合](https://docs.victoriametrics.com/MetricsQL.html#aggregate-functions)[函数](https://docs.victoriametrics.com/MetricsQL.html#aggregate-functions)所产生的最大时间序列数量。
+ `vmselect`的`-search.maxSeries`参数限制`/api/v1/series`接口最多返回的series数量。这个接口主要用于 Grafana 自动补全 Metric 名称，Label 名称 和 Label 值。如果数据库中因为[高基数](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)存储了大量的时间序列，那么这个接口会消耗`vmstorage`和`vmselect`的大量CPU。所以在这种情况下需要使用`-search.maxSeries`来限制下CPU和内存的过度消耗。
+ `-search.maxTagKeys` at `vmstorage` limits the number of items, which may be returned from [/api/v1/labels](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names). This endpoint is used mostly by Grafana for auto-completion of label names. Queries to this endpoint may take big amounts of CPU time and memory at `vmstorage` and `vmselect` when the database contains big number of unique time series because of [high churn rate](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate). In this case it might be useful to set the `-search.maxTagKeys` to quite low value in order to limit CPU and memory usage.
+ `vmstorage`的`-search.maxTagKeys`限制[/api/v1/labels](https://prometheus.io/docs/prometheus/latest/querying/api/#getting-label-names)接口返回的label总数量。这个接口主要用于 Grafana 自动补全 Label 名称。如果数据库中因为[高基数](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)存储了大量的时间序列，那么这个接口会消耗`vmstorage`和`vmselect`的大量CPU。所以在这种情况下需要使用`-search.maxTagKeys`来限制下CPU和内存的过度消耗。
+ `vmstorage`的`-search.maxTagKeys`限制[/api/v1/label/…/values](https://prometheus.io/docs/prometheus/latest/querying/api/#querying-label-values)接口返回的label值总数量。这个接口主要用于 Grafana 自动补全 Label 值。如果数据库中因为[高基数](https://docs.victoriametrics.com/FAQ.html#what-is-high-churn-rate)存储了大量的时间序列，那么这个接口会消耗`vmstorage`和`vmselect`的大量CPU。所以在这种情况下需要使用`-search.maxTagValues`来限制下CPU和内存的过度消耗。
+ `vmstorage`的`-storage.maxDailySeries`可以用于限制每天最多创建多少个新时间序列。见[限制文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#cardinality-limiter)。
+ vmstorage的`-storage.maxHourlySeries`可以用于限制活跃时间序列的数量。见[限制文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#cardinality-limiter)。

也可以参考[容量规划文档](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#capacity-planning)和[vmagent的基数显示器](https://docs.victoriametrics.com/vmagent.html#cardinality-limiter)。

## 高可用
如果数据库在部分组件暂时不可用时仍能接收新数据并处理传入查询，则被认为是高可用的。VictoriaMetrics集群符合这一定义，请参阅[集群可用性文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#cluster-availability)。

建议在具有高带宽、低延迟和低错误率的同一子网络中运行单个集群的所有组件，这可以提高集群的性能和可用性。不建议将单个集群的组件分布在多个可用区（AZ）中，因为跨AZ网络通常带宽较低、延迟较高、错误率也较高，相比之下，单个AZ内的网络表现更好。

如果你需要跨多个AZ的设置，建议在每个AZ中运行独立的集群，并在这些集群前设置[vmagent](https://docs.victoriametrics.com/vmagent.html)，以便它能将传入数据复制到所有集群中，详情请参阅[相关文档](https://docs.victoriametrics.com/vmagent.html#multitenancy)。此外，可以配置额外的vmselect节点，以便根据[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#multi-level-cluster-setup)从多个集群中读取数据。

## 多层联邦部署
当vmselect节点运行时带有`-clusternativeListenAddr`命令行标志，它们可以被其他vmselect节点查询。例如，如果vmselect以`-clusternativeListenAddr=:8401`启动，那么它可以在TCP端口8401上接受来自其他vmselect节点的查询，就像vmstorage节点一样。这允许vmselect节点进行链式连接，并构建多层集群拓扑。例如，顶层vmselect节点可以查询不同可用区（AZ）中的第二层vmselect节点，而第二层vmselect节点可以查询本地AZ中的vmstorage节点。

当vminsert节点运行时带有`-clusternativeListenAddr`命令行标志，它们可以接受来自其他vminsert节点的数据。例如，如果vminsert以`-clusternativeListenAddr=:8400`启动，那么它可以在TCP端口8400上接受来自其他vminsert节点的数据，就像vmstorage节点一样。这允许vminsert节点进行链式连接，并构建多层集群拓扑。例如，顶层vminsert节点可以将数据复制到位于不同可用区（AZ）的第二层vminsert节点中，而第二层vminsert节点可以将数据分散到本地AZ中的vmstorage节点。

由于同步复制和数据分片，vminsert节点的多层集群设置存在以下缺点：

+ 数据写入速度受限于连接到AZ的最慢链路。
+ 当某些可用区（AZ）暂时不可用时，顶层的`vminsert`节点会将传入数据重新路由到剩余的AZ中。这会导致在暂时不可用的AZ中出现数据缺口。

当[vmagent](https://docs.victoriametrics.com/vmagent.html)以[多租户模式](https://docs.victoriametrics.com/vmagent.html#multitenancy)运行时，这些问题得到了解决。当特定AZ暂时不可用时，vmagent会缓冲必须发送到该AZ的数据。缓冲区存储在磁盘上。一旦AZ变得可用，缓冲的数据就会被发送到AZ。

## Helm
Helm图表简化了在Kubernetes中管理VictoriaMetrics集群版本的过程。它可在[helm-charts](https://github.com/VictoriaMetrics/helm-charts)仓库中获得。

## Kubernetes operator
[K8s operator](https://github.com/VictoriaMetrics/operator) 简化了在Kubernetes中管理VictoriaMetrics组件的过程。

## 副本和数据安全
默认情况下，VictoriaMetrics将复制工作卸载到由-storageDataPath指定的底层存储上，如[Google计算引擎的持久磁盘](https://cloud.google.com/compute/docs/disks#pdspecs)，这保证了数据的持久性。如果出于某种原因无法使用复制的持久磁盘，VictoriaMetrics支持应用级别的复制。

通过向vminsert传递`-replicationFactor=N`命令行标志可以启用复制，这指示vminsert在N个不同的vmstorage节点上存储每个摄入样本的N份副本。这保证了即使有最多N-1个vmstorage节点不可用，所有存储的数据仍然可用于查询。

向vmselect传递`-replicationFactor=N`命令行标志指示它不在查询期间如果少于`-replicationFactor`个vmstorage节点不可用时将响应标记为部分响应。详情请参阅[集群可用性文档](https://www.victoriametrics.com.cn/victoriametrics/ji-qun-ban-ben#high-availability)。

为了在`N-1`个存储节点不可用时保持对新摄入数据的给定复制因子，集群必须包含至少`2*N-1`个`vmstorage`节点，其中N是复制因子。

VictoriaMetrics以毫秒精度存储时间戳，因此在启用复制时必须向vmselect节点传递`-dedup.minScrapeInterval=1ms`命令行参数，这样它们在查询期间可以从不同的vmstorage节点上去重复制的样本。如果从配置相同的[vmagent](https://www.victoriametrics.com.cn/victoriametrics/xi-tong-zu-jian/vmagent)实例或Prometheus实例向VictoriaMetrics推送了重复数据，则根据[去重文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#deduplication)，`-dedup.minScrapeInterval`必须设置为抓取配置中的`scrape_interval`。

注意，[复制不能防止灾难](https://medium.com/@valyala/speeding-up-backups-for-big-time-series-databases-533c1a927883)，因此建议定期进行备份。详情请参阅[这些文档](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#backups)。

注意，复制会增加资源使用——CPU、RAM、磁盘空间、网络带宽——最多可达`-replicationFactor=N`倍，因为vminsert将N份摄入数据存储到不同的vmstorage节点上，并且vmselect在查询期间需要去重从vmstorage节点获得的复制数据。因此，将复制工作卸载到由`-storageDataPath`指定的底层复制的持久存储上，如[Google计算引擎的持久磁盘](https://cloud.google.com/compute/docs/disks/#pdspecs)，这可以防止数据丢失和数据损坏，更加成本效益。它还提供持续的高性能，并且可以在不停机的情况下[调整大小](https://cloud.google.com/compute/docs/disks/add-persistent-disk)。基于HDD的持久磁盘应该足以满足大多数用例。建议在Kubernetes中使用耐用的复制持久卷。

## 去重机制
VictoriaMetrics的集群版本支持数据去重，与单节点版本的方式相同。详情请参阅[这些文档](https://docs.victoriametrics.com/#deduplication)。唯一的区别是，由于以下方面，相同的-dedup.minScrapeInterval命令行标志值必须同时传递给vmselect和vmstorage节点：

默认情况下，vminsert尝试将单个时间序列的所有样本路由到单个vmstorage节点。但在某些条件下，单个时间序列的样本可能会分布在多个vmstorage节点上：

+ 当添加/移除vmstorage节点时。此时，部分时间序列的新样本将被路由到其他vmstorage节点；
+ 当vmstorage节点暂时不可用（例如，在它们重启期间）。此时，新样本将被重新路由到剩余的可用vmstorage节点；
+ 当vmstorage节点没有足够的能力处理传入的数据流时。此时，vminsert将新样本重新路由到其他vmstorage节点。

## 备份
建议定期从[即时快照](https://medium.com/@valyala/how-victoriametrics-makes-instant-snapshots-for-multi-terabyte-time-series-data-e1f3fb0e0282)进行备份，以防止用户错误，如意外删除数据。

创建备份时，必须对每个vmstorage节点执行以下步骤：

+ 通过导航到/snapshot/create HTTP处理器创建即时快照。它将创建快照并返回其名称。
+ 使用[vmbackup](https://www.victoriametrics.com.cn/victoriametrics/xi-tong-zu-jian/vmbackup)从`<storageDataPath>/snapshots/<snapshot_name>`文件夹归档创建的快照。归档过程不会干扰vmstorage的工作，因此可以在任何合适的时间进行。
+ 通过`/snapshot/delete?snapshot=<snapshot_name>`或`/snapshot/delete_all`删除未使用的快照，以释放占用的存储空间。

无需在所有vmstorage节点之间同步备份。

从备份中恢复数据：

1. `kill -INT`命令关停 `vmstorage`。
2. 使用 [vmrestore](https://docs.victoriametrics.com/vmrestore.html) 将备份数据恢复到 `-storageDataPath` 指定的目录。
3. 启动 `vmstorage` 节点.

## 保存时间过滤器
VictoriaMetrics 企业版支持通过 label filter 来配置多种数据保留时间，通过 vmstorage 的命令行参数 `-retentionFilter` 来指定。

例如，以下配置将 accountID 从 42 开始的租户的保留期设置为 1 天，然后将任何租户的标签 env="dev" 或 env="prod" 的时间序列的保留期设置为 3 天，而其余租户的保留期为 4 周：


```plain
-retentionFilter='{vm_account_id=~"42.*"}:1d' -retentionFilter='{env=~"dev|staging"}:3d' -retentionPeriod=4w'
```

更多关于保存时间过滤器的详细内容，可以阅读[这些文档](https://docs.victoriametrics.com/#retention-filters)。

## 性能分析
All the cluster components provide the following handlers for [profiling](https://blog.golang.org/profiling-go-programs):

+ `http://vminsert:8480/debug/pprof/heap` 内存剖析和`http://vminsert:8480/debug/pprof/profile` CPU 剖析
+ `http://vmselect:8481/debug/pprof/heap` 内存剖析和`http://vmselect:8481/debug/pprof/profile` CPU 剖析
+ `http://vmstorage:8482/debug/pprof/heap` 内存剖析和`http://vmstorage:8482/debug/pprof/profile` CPU 剖析

从vmstorage收集CPU剖析示例命令（使用 `vmstorage` 的 hostname 替换掉 `0.0.0.0）`：


```plain
Copycurl http://0.0.0.0:8482/debug/pprof/profile > cpu.pprof
```

从 vminsert 收集内存剖析实例命令（使用 `vminsert` 的 hostname 替换掉 `0.0.0.0）`：


```plain
Copycurl http://0.0.0.0:8480/debug/pprof/heap > mem.pprof
```

从安全角度来看，共享收集的剖析是安全的，因为它们不包含敏感信息。

