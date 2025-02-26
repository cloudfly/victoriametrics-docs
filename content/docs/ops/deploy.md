---
title: "安装部署"
date: 2024-11-03T21:32:02+08:00
description: VictoriaMetrics 单机版和集群版的部署教程
keywords:
- 部署
- 教程
weight: 1
---

## 单机版

### 安装
要快速尝试 VictoriaMetrics，只需下载 [VictoriaMetrics 可执行文件](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)或 [Docker 镜像](https://hub.docker.com/r/victoriametrics/victoria-metrics/)，并使用所需的运行参数启动它。还可以参考[快速开始]({{< ref "quickstart" >}})指南获取更多信息。

此外，也可以通过以下方法来安装VictoriaMetrics：

+ [Helm charts](https://github.com/VictoriaMetrics/helm-charts)
+ [Kubernetes operator](https://github.com/VictoriaMetrics/operator)
+ [安装集群版本的 Ansible Role（官方）](https://github.com/VictoriaMetrics/ansible-playbooks)
+ [安装集群版本的 Ansible Role（社区）](https://github.com/Slapper/ansible-victoriametrics-cluster-role)
+ [安装单机版的 Ansible Role（社区）](https://github.com/dreamteam-gg/ansible-victoriametrics-role)
+ [Snap package](https://snapcraft.io/victoriametrics)

### 运行 {#execute}

下面的几个运行参数是最常用的：

+ `-storageDataPath`：VictoriaMetrics 把所有的数据都保存在这个目录。默认的路径是当前工作目录中的`victoria-metrics-data`子目录。
+ `-retentionPeriod`：数据的保留时间。历史的数据会被自动清理删除。默认的保留时间是 1 个月。最小的保留时间是 1 天（即 24 小时）。[点击了解更多详情]({{< relref "./single.md#retention" >}})。

其他的运行参数，建议使用默认值就可以了，只有在有特殊需求的时候再调整他们。用`-help`参数看下[所有可用参数及他们描述和默认值]({{< relref "single.md#flags" >}})。 

正因 VictoriaMetrics 的配置参数都是通过命令行传递的，所以它不支持动态修改配置。如果要修改配置就只能用新的命令行对 VictoriaMetrics 进行重启。步骤如下：

+ 向 VictoriaMetrics 进程发送`SIGINT`信号，让其优雅退出。请参阅[如何向进程发送信号](https://stackoverflow.com/questions/33239959/send-signal-to-process-from-command-line)。 
+ 等待进程退出。可能需要几秒钟时间。 
+ 用新的命令行参数启动 VictoriaMetrics。 

#### 使用 docker-compose
[Docker-compose](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/deployment/docker/docker-compose.yml) 能帮助我们用一条命令加速启动 VictoriaMetrics, [vmagent](https://docs.victoriametrics.com/vmagent.html) 和 Grafana。更多详细信息请查阅[这里](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/master/deployment/docker#folder-contains-basic-images-and-tools-for-building-and-running-victoria-metrics-in-docker)。

#### Systemd Service
参考[这里](https://github.com/VictoriaMetrics/VictoriaMetrics/issues/43)将 VictoriaMetrics 设置为一个 Systemd Service。 我们提供了 [Snap 包](https://snapcraft.io/victoriametrics) 可在 Ubuntu 上直接使用。

下面的几个文档，对初始化 VictoriaMetrics 服务可能会有些帮助：

+ [How to set up scraping of Prometheus-compatible targets](https://docs.victoriametrics.com/#how-to-scrape-prometheus-exporters-such-as-node-exporter)
+ [How to ingest data to VictoriaMetrics](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#how-to-import-time-series-data)
+ [How to set up Prometheus to write data to VictoriaMetrics](https://docs.victoriametrics.com/#prometheus-setup)
+ [How to query VictoriaMetrics via Grafana](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#grafana-setup)
+ [How to query VictoriaMetrics via Graphite API](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#graphite-api-usage)
+ [How to handle alerts](https://docs.victoriametrics.com/Single-server-VictoriaMetrics.html#alerting)

VictoriaMetrics 默认使用 8428 端口处理 [Prometheus 查询请求]({{< relref "../query/api.md#single-prometheus" >}})。建议为 VictoriaMetrics 搭建[监控]({{< relref "single.md#metrics" >}})。

### 环境变量
所有的 VictoriaMetrics 组件都支持在启动参数中使用语法`%{ENV_VAR}`引用环境变量。比如，

在 VictoriaMetrics 启动时，如果环境变量中存在`METRICS_AUTH_KEY=top-secret`，那么`-metricsAuthKey=%{METRICS_AUTH_KEY}`就会自动转换成`metricsAuthKey=top-secret`。这个转换是 VictoriaMetrics 自动做的。

VictoriaMetrics 会递归的转换环境变量。比如我们有 2 个环境变量`BAR=a%{BAZ}`和`BAZ=bc`。那对于`FOO=%{BAR}`就会自动被转换成`FOO=abc`。

此外，所有的 VictoriaMetrics 组件都允许根据以下规则用环境变量设置启动参数：

+ 必须开启`-envflag.enable`启动参数。
+ 参数名中的每一个`.`字符都会被用`_`替代（比如`-insert.maxQueueDuration <duration>`对应的环境变了是`insert_maxQueueDuration=<duration>`）。
+ 对于数组类参数，替代方式是用逗号`,`把多个参数值链接起来（比如`-storageNode <nodeA> -storageNode <nodeB>`对应的环境变量是`storageNode=<nodeA>,<nodeB>`）。
+ 环境变量的前缀可以通过参数`-envflag.prefix`设定. 比如，如果`-envflag.prefix=VM_`, 那么所有环境变量名都要以`VM_`开头。


### 升级
除非[发布日志](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)里特别声明了，否则升级 VictoriaMetrics 到最新版本都是安全的。
跨多个版本升级也是安全的，除非[发布日志](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)里有特别声明。建议定期升级到最新版本，因为最新版可能包含重要的 bugfix、性能优化或新功能。 

除非[发布日志](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)另有说明，降级到旧版本也是安全的。 

在升级/降级过程中必须执行以下步骤：

+ 向 VictoriaMetrics 进程发送`SIGINT`信号让它优雅退出。请参阅[如何向进程发送信号](https://stackoverflow.com/questions/33239959/send-signal-to-process-from-command-line)。 
+ 等待进程退出。这可能需要几秒钟时间。 
+ 启动新版本的 VictoriaMetrics。 

Prometheus 重启不会导致 remote write 丢失数据。详细信息请[参阅本文](https://grafana.com/blog/2019/03/25/whats-new-in-prometheus-2.8-wal-based-remote-write/)。对于 [vmagent](https://docs.victoriametrics.com/vmagent.html) 也一样。

### 构建
我们建议使用[官方发布的二进制](https://github.com/VictoriaMetrics/VictoriaMetrics/releases) 或者 [Docker 镜像](https://hub.docker.com/r/victoriametrics/victoria-metrics/)，不建议使用源代码进行构建。  
构建源代码一般是在你要开发一些定制化需求或者测试 BUG 修复时候才需要。

#### 构建开发环境
1. [安装 Go](https://golang.org/doc/install)。 要求最低版本是 Go 1.19。
2. 在[仓库](https://github.com/VictoriaMetrics/VictoriaMetrics)的根目录运行命令`make victoria-metrics`。该命令会构建`victoria-metrics`二进制然后把它放到`bin`目录中。

#### 构建生产环境
1. [安装 docker](https://docs.docker.com/install/)。
2. 在[仓库](https://github.com/VictoriaMetrics/VictoriaMetrics)的跟目录执行命令`make victoria-metrics-prod`。 命令会构建`victoria-metrics-prod`二进制，并把它放到`bin`目录中.

#### ARM 构建 
ARM 的构建可以在树莓派或 [energy-efficient ARM servers](https://blog.cloudflare.com/arm-takes-wing/)上执行。

#### 开发环境 ARM 构建
1. [安装 Go](https://golang.org/doc/install). 要求最低版本是 Go 1.19。
2. 在[这个仓库](https://github.com/VictoriaMetrics/VictoriaMetrics)根目录执行`make victoria-metrics-linux-arm`或`make victoria-metrics-linux-arm64`. 该命令可以构建出`victoria-metrics-linux-arm`或`victoria-metrics-linux-arm64`二进制，并把它放到`bin`目录中。

#### 生产环境 ARM 构建
1. [安装 docker](https://docs.docker.com/install/).
2. 在[这个仓库](https://github.com/VictoriaMetrics/VictoriaMetrics)根目录执行`make victoria-metrics-linux-arm-prod`或`make victoria-metrics-linux-arm64-prod`. 它构建出`victoria-metrics-linux-arm-prod`或`victoria-metrics-linux-arm64-prod`二进制，并把它放到`bin`目录中。

#### 纯 Go 构建 (CGO_ENABLED=0)

`纯Go`模式构建就是只构建没有 [cgo](https://golang.org/cmd/cgo/) 的依赖的 Go 代码。

1. [安装 Go](https://golang.org/doc/install)。 要求最低版本是 Go 1.19。
2. 在[仓库](https://github.com/VictoriaMetrics/VictoriaMetrics)的根目录执行命令`make victoria-metrics-pure`，命令会构建出二进制`victoria-metrics-pure`，并把它放到`bin`目录中。

#### 构建 Docker 镜像
执行命令`make package-victoria-metrics`。该命令会在本地构建`victoriametrics/victoria-metrics:<PKG_TAG>`的镜像。`<PKG_TAG>`是使用仓库的源代码自动生成的镜像 Tag。`<PKG_TAG>`可以通过环境变量指定，比如执行命令`PKG_TAG=foobar make package-victoria-metrics`。

基础镜像用的是 [alpine](https://hub.docker.com/_/alpine)，但是可以使用`<ROOT_IMAGE>`环境变量指定使用其他基础镜像。
比如，下面的命令就是使用 [scratch](https://hub.docker.com/_/scratch) 作为我们的基础镜像:

```plain
ROOT_IMAGE=scratch make package-victoria-metrics
```

## 集群版 {#cluster}

一个集群至少包含下面几项：

+ 一个`vmstorage`节点，需要指定`-retentionPeriod`和`-storageDataPath`参数
+ 一个`vminsert`节点，需要指定`-storageNode=<vmstorage_host>`
+ 一个`vmselect`节点，需要指定`-storageNode=<vmstorage_host>`

建议每个服务至少运行两个实例，来保证高可用。在这种情况下，当一个实例暂时不可用时，集群仍可继续工作，其余节点可以处理增加的工作量。

最好运行许多小型 vmstorage 节点而非少量大型 vmstorage 节点，因为当某些 vmstorage 节点不可用时，这可以减少剩余 vmstorage 实例的压力增加。

必须在 vminsert 和 vmselect 节点前放置一个 http 负载均衡器，例如 [vmauth](https://docs.victoriametrics.com/vmauth.html) 或 nginx。它必须根据 [url 格式](https://docs.victoriametrics.com/Cluster-VictoriaMetrics.html#url-format)包含以下路由配置：

+ 带有`/insert`前缀的请求必须被路由到 vminsert 实例的 8480 端口数。
+ 带有`/select`前缀的请求必须被路由到 vmselect 实例的 8481 端口数。

端口可以通过`-httpListenAddr`参数来设定。

建议为集群配置上[监控]({{< relref "../ops/cluster.md#monitoring" >}})。

下面的工具可以简化集群部署：

+ [使用 docker compose 部署 VictoriaMetrics 集群的样例](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/master/deployment/docker/docker-compose-cluster.yml)
+ [Helm charts for VictoriaMetrics](https://github.com/VictoriaMetrics/helm-charts)
+ [Kubernetes operator for VictoriaMetrics](https://github.com/VictoriaMetrics/operator)

可以在单个主机上手动设置一个玩具集群。在这种情况下，每个集群组件 - vminsert、vmselect 和 vmstorage - 必须使用`-httpListenAddr`启动参数指定不同的端口。此参数指定用于接受[监控]({{< relref "../ops/cluster.md#monitoring" >}})和 Profiling 的 http 请求的地址。`vmstorage`实例必须对下面你的参数设定不同地址参数，以避免端口冲突：

+ `-storageDataPath`- 每个`vmstorage`实例都不行有一个专用的数据存储路径。
+ `-vminsertAddr`- 每个`vmstorage`实例必须监听一个 tcp 地址，用来接受 vminsert 发送过来的数据。
+ `-vmselectAddr`- 每个`vmstorage`实例必须监听一个 tcp 地址，用来处理 vmselect 发送过来的查询请求。


### 二进制
集群版本的二进制文件可在[发布页面](https://github.com/VictoriaMetrics/VictoriaMetrics/releases)的 assets 部分中找到。

集群版本的 Docker 镜像可在此处找到：

+ `vminsert`- [https://hub.docker.com/r/victoriametrics/vminsert/tags](https://hub.docker.com/r/victoriametrics/vminsert/tags)
+ `vmselect`- [https://hub.docker.com/r/victoriametrics/vmselect/tags](https://hub.docker.com/r/victoriametrics/vmselect/tags)
+ `vmstorage`- [https://hub.docker.com/r/victoriametrics/vmstorage/tags](https://hub.docker.com/r/victoriametrics/vmstorage/tags)

### 构建
集群版本的源代码可在 [cluster 分支](https://github.com/VictoriaMetrics/VictoriaMetrics/tree/cluster)中获取。

#### 生产环境构建
无需在系统上安装 Go，因为二进制文件是在 [Go 的官方 docker 容器](https://hub.docker.com/_/golang)内构建的。因此，[安装 docker](https://docs.docker.com/install/) 并运行以下命令：


```sh
make vminsert-prod vmselect-prod vmstorage-prod
```

产生的二进制文件被放入带有`-prod`后缀的`bin`文件夹中：


```sh
$ make vminsert-prod vmselect-prod vmstorage-prod
$ ls -1 bin
vminsert-prod
vmselect-prod
vmstorage-prod
```

#### 开发环境构建
1. [安装Go](https://golang.org/doc/install)，最低支持版本是 Go1.18。
2. 从[仓库根目录](https://github.com/VictoriaMetrics/VictoriaMetrics)运行`make`。它应该构建`vmstorage`、`vmselect`和`vminsert`二进制文件并将它们放入`bin`文件夹中。

#### 构建 docker 镜像
执行`make package`命令，会在本地构建下面几个 docker 镜像：

+ `victoriametrics/vminsert:<PKG_TAG>`
+ `victoriametrics/vmselect:<PKG_TAG>`
+ `victoriametrics/vmstorage:<PKG_TAG>`

`<PKG_TAG>`是根据[仓库中的源码](https://github.com/VictoriaMetrics/VictoriaMetrics)自动生成的 image tag。`<PKG_TAG>`可以使用环境变量来指定，比如：`PKG_TAG=foobar make package`.

默认情况下，为了提高可调试性，镜像是在 [alpine image](https://hub.docker.com/_/scratch) 之上构建的。可以通过`ROOT_IMAGE`环境变量设置在其他基础镜像之上构建镜像。例如，以下命令在[临时镜像](https://hub.docker.com/_/scratch)之上构建镜像：


```sh
ROOT_IMAGE=scratch make package
```

### vmstorage 自动发现

只有企业版支持`vminsert`和`vmselect`对`vmstorage`实例自动服务发现，开源版的话需要进行二次开发。

VictoriaMetrics 的代码质量很高，所以二次开发也比较简单。只需要参考[netstorage.Init](https://github.com/VictoriaMetrics/VictoriaMetrics/blob/cluster/app/vminsert/netstorage/netstorage.go#L507)实现即可，仅有 2 行代码。这里给出一个代码实现参考：


```go {filename=netstorage.go}
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

将上面的函数放到`netstorage.go`中，自己再实现发现实例列表的方法，在方法里面调用该`ResetStorageNodes`方法即可。

### Helm
Helm Chart 简化了在 Kubernetes 中管理 VictoriaMetrics 集群版本的过程。它可在 [helm-charts](https://github.com/VictoriaMetrics/helm-charts) 仓库中获得。

### Kubernetes operator

[K8s operator](https://github.com/VictoriaMetrics/operator) 简化了在 Kubernetes 中管理 VictoriaMetrics 组件的过程。