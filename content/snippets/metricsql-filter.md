---
title: "MetricsQL 过滤器"
---


我们用 MetricsQL 获取指标`foo_bar`的数据。只需在查询中写入指标名称，就能轻松完成：

```
foo_bar
```

一个简单的指标名称会得到拥有不同 Label Set 的多个 Timeseries 返回响应值。比如：

```
requests_total{path="/", code="200"} 
requests_total{path="/", code="403"}
```

要选择具有特定 Label 的 Timeseries，需要在花括号`{}`中指定匹配 Label 的过滤器：

```
requests_total{code="200"}
```

上面的查询语句返回所有名字是`requests_total `并且 Label 带有`code="200"`的所有`Timeseries`。我们用`=`运算符来匹配 Label 值。对于反匹配使用`!=`运算符。过滤器也通过`=~`实现正则匹配，用`!~`实现正则反匹配。

```
requests_total{code=~"2.*"}
```

过滤器也可以被组合使用：

```
requests_total{code=~"200", path="/home"}
```

上面的查询返回所有名字是`request_total`，同时带有`code="200"`和`path="/home"`Label 的所有 Timeseries。
