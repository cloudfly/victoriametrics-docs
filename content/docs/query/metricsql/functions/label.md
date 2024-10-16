---
title: 操作 Label
weight: 2
---

Label 操作函数对选定的 Rollup 计算结果进行 Label 转换。

附加细节：

+ 如果 Label 操作函数直接应用于`series_selector`，那么在执行 Label 转换之前，会自动应用[`default_rollup`](./rollup.md#default_rollup)函数。例如，`alias(temperature, "foo")`会被隐式转换为`alias(default_rollup(temperature), "foo")`。

请参阅[隐式查询转换]({{< relref "../_index.md#conversion" >}})。

支持的 Label 操作函数如下：

### alias
`alias(q, "name")`将`q`返回的所有时间序列更名为`name`。例如，`alias(up, "foobar")`会将`up`序列重命名为`foobar`序列。

### drop_common_labels
`drop_common_labels(q1, ...., qN)`会删除`q1, ..., qN`返回的时间序列中共有的`label="value"`。

### label_copy
`label_copy(q, "src_label1", "dst_label1", ..., "src_labelN", "dst_labelN")`将`src_label*`的 Label 值复制到`q`返回的所有时间序列的`dst_label*`。如果`src_label`为空，则相应的`dst_label`保持不变。

### label_del
`label_del(q, "label1", ..., "labelN")`删除`q`返回的所有时间序列中名为`label*`的所有 Label。

### label_join
`label_join(q, "dst_label", "separator", "src_label1", ..., "src_labelN")`

它将`src_label*`的值用给定的`separator`连接起来，并将结果存储在`dst_label`中。这是针对`q`返回的每条时间序列独立执行的。例如，`label_join(up{instance="xxx",job="yyy"}, "foo", "-", "instance", "job")`会将`xxx-yyy`标签值存储到`foo`标签中。

该函数在 PromQL 中也支持。

### label_keep
`label_keep(q, "label1", ..., "labelN")`删除`q`返回的所有时间序列中除列出的`label*`Label 之外的其他所有 Label。

### label_lowercase
`label_lowercase(q, "label1", ..., "labelN")`将`q`返回的所有时间序列中名为`label*`的 Label 值转换成小写字母。

### label_map
`label_map(q, "label", "src_value1", "dst_value1", ..., "src_valueN", "dst_valueN")`遍历`q`返回的所有时间序列，将所有 Label 值是`src_value*`的 Label 值对应的`dst_value*`。

### label_match
`label_match(q, "label", "regexp")`会删除`q`中`label`值不匹配给定正则表达式`regexp`的时间序列。此函数在类 rollup 函数之后会比较有用，因为这些类 rollup 函数可能会为每个输入序列返回多个时间序列。  
另请参见 [label_mismatch](#label_mismatch) 和 [labels_equal](#labels_equal)。

### label_mismatch
`label_mismatch(q, "label", "regexp")`会删除`q`中`label`值匹配给定正则表达式`regexp`的时间序列。此函数在类 rollup 函数之后会比较有用，因为这些类 rollup 函数可能会为每个输入序列返回多个时间序列。

See also [label_match](#label_match) and [labels_equal](#labels_equal).

### label_move
`label_move(q, "src_label1", "dst_label1", ..., "src_labelN", "dst_labelN")`它将`src_label*`的 Label 值移动到`q`返回的所有时间序列的`dst_label*`。如果`src_label`为空，则相应的`dst_label`保持不变。

### label_replace
`label_replace(q, "dst_label", "replacement", "src_label", "regex")`它将给定的正则表达式`regexp`应用于`src_label`，如果给定的正则表达式匹配`src_label`，则将替换内容存储在`dst_label`中。替换内容可以包含对正则表达式捕获组的引用，例如`$1`、`$2`等。这些引用会被相应的正则表达式捕获组替换。例如，`label_replace(up{job="node-exporter"}, "foo", "bar-$1", "job", "node-(.+)")`会将`bar-exporter`标签值存储到`foo`标签中。

该函数在 PromQL 中也支持。

### label_set
`label_set(q, "label1", "value1", ..., "labelN", "valueN")`将`{label1="value1", ..., labelN="valueN"}`这些 Label 添加到`q`返回的每条时间序列数据里。

### label_transform
`label_transform(q, "label", "regexp", "replacement")`将给定`label`中所有匹配正则表达式`regexp`的部分替换为指定的`replacement`。

### label_uppercase
`label_uppercase(q, "label1", ..., "labelN")`将`q`返回的所有时间序列中名为`label*`的 Label 值转换成大写字母。

另请参见 [label_lowercase](#label_lowercase).

### label_value
`label_value(q, "label")`它为`q`返回的每条时间序列中的给定 label 的值作为指标 value 返回（原指标 value 被忽略）。

例如，如果`label_value(foo, "bar")`应用于`foo{bar="1.234"}`，那么它将返回一个值为`1.234`的时间序列`foo{bar="1.234"}`. 对于 label 值是非数值类型情况，该函数将不返回数据。

### labels_equal
`labels_equal(q, "label1", "label2", ...)`在 q 返回每条时间序列里，寻找`“label1”`、`“label2”`值相等的时间序列，并返回。

另请参阅 [label_match](#label_match) 和 [label_mismatch](#label_mismatch).

### sort_by_label
`sort_by_label(q, "label1", ... "labelN")`根据给定的一组 Label 按升序排序序列。例如，`sort_by_label(foo, "bar")`会根据这些序列中 Label `bar`的值对`foo`序列进行排序。

另请参阅 [sort_by_label_desc](#sort_by_label_desc) 和 [sort_by_label_numeric](#sort_by_label_numeric).

### sort_by_label_desc
`sort_by_label`的反向操作，即降序排列。

### sort_by_label_numeric
`sort_by_label_numeric(q, "label1", ... "labelN")`is [label manipulation function](#label-manipulation-functions), which sorts series in ascending order by the given set of labels using [numeric sort](https://www.gnu.org/software/coreutils/manual/html_node/Version-sort-is-not-the-same-as-numeric-sort.html). For example, if `foo`series have `bar`label with values `1`, `101`, `15`and `2`, then `sort_by_label_numeric(foo, "bar")`would return series in the following order of `bar`label values: `1`, `2`, `15`and `101`.

`sort_by_label_numeric(q, "label1", ... "labelN")`根据给定的一组 Label 使用数值排序，按升序排序序列。例如，如果`foo`序列的`bar`标签值为`1`、`101`、`15`和`2`，那么`sort_by_label_numeric(foo, "bar")`会按`bar`标签值的以下顺序返回序列：`1`、`2`、`15`和`101`。

另请参阅 [sort_by_label_numeric_desc](#sort_by_label_numeric_desc) 和 [sort_by_label](#sort_by_label).

### sort_by_label_numeric_desc
`sort_by_label_numeric`的反向操作，即降序排列。

