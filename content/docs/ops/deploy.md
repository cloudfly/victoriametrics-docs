---
title: "安装部署"
weight: 1
---

## 单机版

### 安装
要快速尝试VictoriaMetrics，只需下载[VictoriaMetrics可执行文件](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)或[Docker镜像](https://hub.docker.com/r/victoriametrics/victoria-metrics/)，并使用所需的运行参数启动它。还可以参考[快速开始]({{< ref "quickstart" >}})指南获取更多信息。

此外，也可以通过以下方法来安装VictoriaMetrics：

+ [Helm charts](https://github.com/VictoriaMetrics/helm-charts)
+ [Kubernetes operator](https://github.com/VictoriaMetrics/operator)
+ [安装集群版本的 Ansible Role（官方）](https://github.com/VictoriaMetrics/ansible-playbooks)
+ [安装集群版本的 Ansible Role（社区）](https://github.com/Slapper/ansible-victoriametrics-cluster-role)
+ [安装单机版的 Ansible Role（社区）](https://github.com/dreamteam-gg/ansible-victoriametrics-role)
+ [Snap package](https://snapcraft.io/victoriametrics)

### 运行 {#execute}

下面的几个运行参数是最常用的：

+ `-storageDataPath`：VictoriaMetrics 把所有的数据都保存在这个目录。默认的路径是当前工作目录中的`victoria-metrics-data` 子目录。
+ `-retentionPeriod`：数据的保留时间。历史的数据会被自动清理删除。默认的保留时间是 1 个月。最小的保留时间是 1 天（即 24 小时）。[点击了解更多详情](#deduplication)。

其他的运行参数，基本使用默认值就可以了，所以只有在有特殊需求的时候再修改他们就行。用`-help` 参数看下[所有可用参数及他们描述和默认值]({{< relref "single.md#flags" >}})。 

正因 VictoriaMetrics 的配置参数都是通过命令行传递的，所以它不支持动态修改配置。如果要修改配置就只能用新的命令行对 VictoriaMetrics 进行重启。步骤如下：

+ 向VictoriaMetrics进程发送`SIGINT`信号以正常停止它。请参阅[如何向进程发送信号](https://stackoverflow.com/questions/33239959/send-signal-to-process-from-command-line)。 
+ 等待进程停止。这可能需要几秒钟时间。 
+ 启动已升级的VictoriaMetrics。 

下面的几个文档，对初始化 VictoriaMetrics 可能会有些帮助：

+ [How to set up scraping of Prometheus-compatible targets](https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter)
+ [How to ingest data to VictoriaMetrics](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-time-series-data)
+ [How to set up Prometheus to write data to VictoriaMetrics](https://docs.victoriametrics.com/#prometheus-setup)
+ [How to query VictoriaMetrics via Grafana](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#grafana-setup)
+ [How to query VictoriaMetrics via Graphite API](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-api-usage)
+ [How to handle alerts](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#alerting)

VictoriaMetrics 默认使用 8428 端口处理 [Prometheus 查询请求]({{< relref "../query/http.md#single-prometheus" >}})。建议为 VictoriaMetrics 搭建[监控]({{< relref "single.md#metrics" >}})。

### 环境变量
所有的 VictoriaMetrics 组件都支持在命令行参数中使用语法`%{ENV_VAR}`引用环境变量。比如，

在 VictoriaMetrics 启动时，如果环境变量中存在`METRICS_AUTH_KEY=top-secret`，那么`-metricsAuthKey=%{METRICS_AUTH_KEY}`就会自动转换成`metricsAuthKey=top-secret`。这个转换是 VictoriaMetrics 自动做的。

VictoriaMetrics 会递归的转换环境变量。比如我们有 2 个环境变量 `BAR=a%{BAZ}` 和 `BAZ=bc`。那对于 `FOO=%{BAR}` 就会自动被转换成`FOO=abc`。

此外，所有的VictoriaMetrics组件都允许根据以下规则通过环境变量设置参数：

Additionally, all the VictoriaMetrics components allow setting flag values via environment variables according to these rules:

+ `-envflag.enable` 参数必须开启。
+ 参数名中的每一个`.`字符都会被用`_`替代（比如`-insert.maxQueueDuration <duration>` 会被转换成`insert_maxQueueDuration=<duration>`）。
+ 对于重复参数，有一个替代方式就是用逗号`,`把多个参数值链接起来（比如 `-storageNode <nodeA> -storageNode <nodeB>` 会被转换成 `storageNode=<nodeA>,<nodeB>`）。
+ 环境变量的前缀可以通过参数 `-envflag.prefix` 设定. 比如，如果`-envflag.prefix=VM_`, 那么所有环境变量名都要以 `VM_`开头。

## 集群版

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

### vmstorage 自动发现
只有企业版支持`vminsert `和` vmselect `对` vmstorage`实例自动服务发现，开源版的话需要进行二次开发。

VictoriaMetrics 的代码质量很高，所以二次开发也比较简单。只需要参考[netstorage.Init](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/cluster/app/vminsert/netstorage/netstorage.go#L507)实现即可，仅有 2 行代码。这里给出一个代码实现参考：


```go
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