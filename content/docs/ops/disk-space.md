---
title: "如何处理磁盘空间不足"
weight: 3
---

磁盘空间属于前期规划的，这种事故主要是因为前期规划失误。只能临时补救。具体有如下集中方法

## 强行 merge
让 vmstorage 执行 merge，会将多个 part merge 成一个 part，减少磁盘空间。有数据持续写入的 partition 会自动触发 merge，不要去强制 merge。所以只对历史 partition 进行 merge。

```shell
## 参数 partition_prefix 指定 partition，partition 的名字在 $DATA/data/small 下可以看到
curl 'http://localhost:8442/internal/force_merge?partition_prefix=2022_01'
```

效果如图所示：

![](disk-usage.png)

磁盘使用率上升是因为 merge 过程创建新的 part 来  merge 老的多个 parts。突然下降代表 merge 结束，删掉老的 parts。

整个 merge 过程，CPU 和 Memory 几乎没有什么影响。merge 的耗时数个小时，跟数据量大小有关。

## 等待
如上所述，系统对多个 part 进行 merge 时，会临时使用一定的磁盘空间，合并后将老的 part 删除就会释放。

因此在磁盘不足时，可查看 vmstorage 是否正在执行 merge，如果是，可以等待其执行完毕。一次 merge 可能会执行是个小时甚至数天。

## 删除 cache
如果 cache 目录比较大，可以删除。但通常不会太大。

## 强制删除历史 partition
删除历史数据是最直接的。

1. 先 stop 掉 vmstorage 组件。
2. 删除 `$DATA/data/{big,small}/YYYY_MM` 目录。
3. 启动 vmstorage。

## 只有一个 partition ?
也就是这一个月而数据磁盘都扛不住，那么只能删除 part。part 的文件夹名称，包含着这个 part 的时间范围。可以根据这些数据删除历史 part。

```plain
./small/2022_02/93109700891_21411093_20220201043320.000_20220204141544.799_16CF806E39D42DF8
```

## 修改 retention
直接修改 vmstorage 的运行参数，让 retention 更短。然后重启，让 vmstorage 自己去删过期的 partition 也是OK的。

不过这就是永久生效了，而不是临时删下历史数据清理磁盘。

## <font style="color:rgb(216,57,49);">不要删 Series</font>
<font style="color:rgb(216,57,49);">因为删除 series 会带来额外很大的开销，让系统不稳定。而且它不会释放多少空间。</font>

