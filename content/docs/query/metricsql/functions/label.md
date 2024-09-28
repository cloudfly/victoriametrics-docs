---
title: 操作 Label
weight: 2
---


<font style="color:rgb(34, 34, 34);">Label 操作函数对选定的 Rollup 计算结果进行 Label 转换。</font>

<font style="color:rgb(34, 34, 34);">附加细节：</font>

+ <font style="color:rgb(34, 34, 34);">如果 Label 操作函数直接应用于</font>`<font style="color:rgb(34, 34, 34);">series_selector</font>`<font style="color:rgb(34, 34, 34);">，那么在执行 Label 转换之前，会自动应用</font>`[default_rollup](https://docs.victoriametrics.com/metricsql/#default_rollup)<font style="color:rgb(34, 34, 34);">()</font>`<font style="color:rgb(34, 34, 34);">函数。例如，</font>`<font style="color:rgb(34, 34, 34);">alias(temperature, "foo")</font>`<font style="color:rgb(34, 34, 34);"> 会被隐式转换为 </font>`<font style="color:rgb(34, 34, 34);">alias(default_rollup(temperature), "foo")</font>`<font style="color:rgb(34, 34, 34);">。</font>

<font style="color:rgb(34, 34, 34);">请参阅</font>[隐式查询转换](implicit query conversions)<font style="color:rgb(34, 34, 34);">。</font>

支持的 Label 操作函数如下：

### alias
`alias(q, "name")` 将`q`返回的所有时间序列更名为`name`。例如，`alias(up, "foobar")` 会将`up`序列重命名为`foobar` 序列。

### drop_common_labels
`drop_common_labels(q1, ...., qN)`会删除 `q1, ..., qN` 返回的时间序列中共有的`label="value"`。

### label_copy
`label_copy(q, "src_label1", "dst_label1", ..., "src_labelN", "dst_labelN")`<font style="color:rgb(31, 35, 41);">将</font>`<font style="color:rgb(31, 35, 41);">src_label*</font>`<font style="color:rgb(31, 35, 41);">的 Label 值复制到</font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);">返回的所有时间序列的</font>`<font style="color:rgb(31, 35, 41);">dst_label*</font>`<font style="color:rgb(31, 35, 41);">。如果</font>`<font style="color:rgb(31, 35, 41);">src_label</font>`<font style="color:rgb(31, 35, 41);">为空，则相应的 </font>`<font style="color:rgb(31, 35, 41);">dst_label</font>`<font style="color:rgb(31, 35, 41);">保持不变。</font>

### label_del
`label_del(q, "label1", ..., "labelN")` <font style="color:rgb(31, 35, 41);">删除</font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);">返回的所有时间序列中名为</font>`<font style="color:rgb(31, 35, 41);">label*</font>`<font style="color:rgb(31, 35, 41);">的所有 Label。</font>

### label_join
`label_join(q, "dst_label", "separator", "src_label1", ..., "src_labelN")`

<font style="color:rgb(31, 35, 41);">它将</font>`<font style="color:rgb(31, 35, 41);">src_label*</font>`<font style="color:rgb(31, 35, 41);">的值用给定的</font>`<font style="color:rgb(31, 35, 41);">separator</font>`<font style="color:rgb(31, 35, 41);">连接起来，并将结果存储在</font>`<font style="color:rgb(31, 35, 41);">dst_label</font>`<font style="color:rgb(31, 35, 41);">中。这是针对 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的每条时间序列独立执行的。例如，</font>`<font style="color:rgb(31, 35, 41);">label_join(up{instance="xxx",job="yyy"}, "foo", "-", "instance", "job")</font>`<font style="color:rgb(31, 35, 41);"> 会将</font>`<font style="color:rgb(31, 35, 41);">xxx-yyy</font>`<font style="color:rgb(31, 35, 41);">标签值存储到</font>`<font style="color:rgb(31, 35, 41);">foo</font>`<font style="color:rgb(31, 35, 41);">标签中。</font>

<font style="color:rgb(31, 35, 41);">该函数在 PromQL 中也支持。</font>

### label_keep
`label_keep(q, "label1", ..., "labelN")`<font style="color:rgb(31, 35, 41);">删除 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的所有时间序列中除列出的 </font>`<font style="color:rgb(31, 35, 41);">label*</font>`<font style="color:rgb(31, 35, 41);"> Label 之外的其他所有 Label。</font>

### label_lowercase
`label_lowercase(q, "label1", ..., "labelN")`<font style="color:rgb(31, 35, 41);">将 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的所有时间序列中名为</font>`<font style="color:rgb(31, 35, 41);">label*</font>`<font style="color:rgb(31, 35, 41);">的 Label 值转换成小写字母。</font>

### label_map
`label_map(q, "label", "src_value1", "dst_value1", ..., "src_valueN", "dst_valueN")`<font style="color:rgb(31, 35, 41);">遍历 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的所有时间序列，将所有 Label 值是</font>`<font style="color:rgb(31, 35, 41);">src_value*</font>`<font style="color:rgb(31, 35, 41);">的 Label 值对应的</font>`<font style="color:rgb(31, 35, 41);">dst_value*</font>`<font style="color:rgb(31, 35, 41);">。</font>

### label_match
`label_match(q, "label", "regexp")`<font style="color:rgb(34, 34, 34);">会删除 </font>`<font style="color:rgb(34, 34, 34);">q</font>`<font style="color:rgb(34, 34, 34);"> 中</font>`<font style="color:rgb(34, 34, 34);">label</font>`<font style="color:rgb(34, 34, 34);">值不匹配给定正则表达式</font>`<font style="color:rgb(34, 34, 34);">regexp</font>`<font style="color:rgb(34, 34, 34);">的时间序列。</font>**<font style="color:rgb(34, 34, 34);">此函数在类 rollup 函数之后会比较有用，因为这些类 rollup 函数可能会为每个输入序列返回多个时间序列。</font>**  
<font style="color:rgb(34, 34, 34);">另请参见 </font>[label_mismatch](https://docs.victoriametrics.com/metricsql/#label_mismatch)<font style="color:rgb(34, 34, 34);"> 和 </font>[labels_equal](https://docs.victoriametrics.com/metricsql/#labels_equal)<font style="color:rgb(34, 34, 34);">。</font>

### label_mismatch
`label_mismatch(q, "label", "regexp")`<font style="color:rgb(34, 34, 34);">会删除 </font>`<font style="color:rgb(34, 34, 34);">q</font>`<font style="color:rgb(34, 34, 34);"> 中</font>`<font style="color:rgb(34, 34, 34);">label</font>`<font style="color:rgb(34, 34, 34);">值匹配给定正则表达式</font>`<font style="color:rgb(34, 34, 34);">regexp</font>`<font style="color:rgb(34, 34, 34);">的时间序列。</font>**<font style="color:rgb(34, 34, 34);">此函数在类 rollup 函数之后会比较有用，因为这些类 rollup 函数可能会为每个输入序列返回多个时间序列。</font>**

See also [label_match](https://docs.victoriametrics.com/metricsql/#label_match) and [labels_equal](https://docs.victoriametrics.com/metricsql/#labels_equal).

### label_move
`label_move(q, "src_label1", "dst_label1", ..., "src_labelN", "dst_labelN")`<font style="color:rgb(31, 35, 41);">它将</font>`<font style="color:rgb(31, 35, 41);">src_label*</font>`<font style="color:rgb(31, 35, 41);">的 Label 值移动到</font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);">返回的所有时间序列的</font>`<font style="color:rgb(31, 35, 41);">dst_label*</font>`<font style="color:rgb(31, 35, 41);">。如果 </font>`<font style="color:rgb(31, 35, 41);">src_label</font>`<font style="color:rgb(31, 35, 41);"> 为空，则相应的 </font>`<font style="color:rgb(31, 35, 41);">dst_label</font>`<font style="color:rgb(31, 35, 41);"> 保持不变。</font>

### label_replace
`label_replace(q, "dst_label", "replacement", "src_label", "regex")`<font style="color:rgb(31, 35, 41);">它将给定的正则表达式 </font>`<font style="color:rgb(31, 35, 41);">regexp</font>`<font style="color:rgb(31, 35, 41);"> 应用于 </font>`<font style="color:rgb(31, 35, 41);">src_label</font>`<font style="color:rgb(31, 35, 41);">，如果给定的正则表达式匹配 </font>`<font style="color:rgb(31, 35, 41);">src_label</font>`<font style="color:rgb(31, 35, 41);">，则将替换内容存储在 </font>`<font style="color:rgb(31, 35, 41);">dst_label</font>`<font style="color:rgb(31, 35, 41);"> 中。替换内容可以包含对正则表达式捕获组的引用，例如 </font>`<font style="color:rgb(31, 35, 41);">$1</font>`<font style="color:rgb(31, 35, 41);">、</font>`<font style="color:rgb(31, 35, 41);">$2</font>`<font style="color:rgb(31, 35, 41);"> 等。这些引用会被相应的正则表达式捕获组替换。例如，</font>`<font style="color:rgb(31, 35, 41);">label_replace(up{job="node-exporter"}, "foo", "bar-$1", "job", "node-(.+)")</font>`<font style="color:rgb(31, 35, 41);"> 会将 </font>`<font style="color:rgb(31, 35, 41);">bar-exporter</font>`<font style="color:rgb(31, 35, 41);"> 标签值存储到 </font>`<font style="color:rgb(31, 35, 41);">foo</font>`<font style="color:rgb(31, 35, 41);"> 标签中。</font>

<font style="color:rgb(31, 35, 41);">该函数在 PromQL 中也支持。</font>

### label_set
`label_set(q, "label1", "value1", ..., "labelN", "valueN")`将`{label1="value1", ..., labelN="valueN"}`这些 Label 添加到`q`返回的每条时间序列数据里。

### label_transform
`label_transform(q, "label", "regexp", "replacement")` <font style="color:rgb(31, 35, 41);">将给定 </font>`<font style="color:rgb(31, 35, 41);">label</font>`<font style="color:rgb(31, 35, 41);"> 中所有匹配正则表达式 </font>`<font style="color:rgb(31, 35, 41);">regexp</font>`<font style="color:rgb(31, 35, 41);"> 的部分替换为指定的 </font>`<font style="color:rgb(31, 35, 41);">replacement</font>`<font style="color:rgb(31, 35, 41);">。</font>

### label_uppercase
`label_uppercase(q, "label1", ..., "labelN")`<font style="color:rgb(31, 35, 41);">将 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的所有时间序列中名为</font>`<font style="color:rgb(31, 35, 41);">label*</font>`<font style="color:rgb(31, 35, 41);">的 Label 值转换成大写字母。</font>

另请参见 [label_lowercase](https://docs.victoriametrics.com/metricsql/#label_lowercase).

### label_value
`label_value(q, "label")`<font style="color:rgb(31, 35, 41);">它为 </font>`<font style="color:rgb(31, 35, 41);">q</font>`<font style="color:rgb(31, 35, 41);"> 返回的每条时间序列中的给定 label 的值作为指标 value 返回（原指标 value 被忽略）。</font>

<font style="color:rgb(31, 35, 41);">例如，如果 </font>`<font style="color:rgb(31, 35, 41);">label_value(foo, "bar")</font>`<font style="color:rgb(31, 35, 41);"> 应用于 </font>`<font style="color:rgb(31, 35, 41);">foo{bar="1.234"}</font>`<font style="color:rgb(31, 35, 41);">，那么它将返回一个值为</font>`<font style="color:rgb(31, 35, 41);">1.234</font>`<font style="color:rgb(31, 35, 41);">的时间序列</font>`<font style="color:rgb(31, 35, 41);">foo{bar="1.234"}</font>`<font style="color:rgb(31, 35, 41);">. 对于 label 值是非数值类型情况，该函数将不返回数据。</font>

### labels_equal
`labels_equal(q, "label1", "label2", ...)`在 q <font style="color:rgb(34, 34, 34);">返回每条时间序列里，寻找 </font>`<font style="color:rgb(34, 34, 34);">“label1”</font>`<font style="color:rgb(34, 34, 34);">、</font>`<font style="color:rgb(34, 34, 34);">“label2”</font>`<font style="color:rgb(34, 34, 34);"> 值相等的时间序列，并返回。</font>

另请参阅 [label_match](https://docs.victoriametrics.com/metricsql/#label_match) 和 [label_mismatch](https://docs.victoriametrics.com/metricsql/#label_mismatch).

### sort_by_label
`<font style="color:rgb(31, 35, 41);">sort_by_label(q, "label1", ... "labelN")</font>`<font style="color:rgb(31, 35, 41);">根据给定的一组 Label 按升序排序序列。例如，</font>`<font style="color:rgb(31, 35, 41);">sort_by_label(foo, "bar")</font>`<font style="color:rgb(31, 35, 41);"> 会根据这些序列中 Label </font>`<font style="color:rgb(31, 35, 41);">bar</font>`<font style="color:rgb(31, 35, 41);">的值对</font>`<font style="color:rgb(31, 35, 41);">foo</font>`<font style="color:rgb(31, 35, 41);">序列进行排序。</font>

另请参阅 [sort_by_label_desc](https://docs.victoriametrics.com/metricsql/#sort_by_label_desc) 和 [sort_by_label_numeric](https://docs.victoriametrics.com/metricsql/#sort_by_label_numeric).

### sort_by_label_desc
`<font style="color:rgb(31, 35, 41);">sort_by_label</font>`<font style="color:rgb(31, 35, 41);"> 的反向操作，即降序排列。</font>

### sort_by_label_numeric
`sort_by_label_numeric(q, "label1", ... "labelN")` is [label manipulation function](https://docs.victoriametrics.com/metricsql/#label-manipulation-functions), which sorts series in ascending order by the given set of labels using [numeric sort](https://www.gnu.org/software/coreutils/manual/html_node/Version-sort-is-not-the-same-as-numeric-sort.html). For example, if `foo` series have `bar` label with values `1`, `101`, `15` and `2`, then `sort_by_label_numeric(foo, "bar")` would return series in the following order of `bar` label values: `1`, `2`, `15` and `101`.

`<font style="color:rgb(31, 35, 41);">sort_by_label_numeric(q, "label1", ... "labelN")</font>`<font style="color:rgb(31, 35, 41);">根据给定的一组 Label 使用数值排序，按升序排序序列。例如，如果 </font>`<font style="color:rgb(31, 35, 41);">foo</font>`<font style="color:rgb(31, 35, 41);"> 序列的 </font>`<font style="color:rgb(31, 35, 41);">bar</font>`<font style="color:rgb(31, 35, 41);"> 标签值为 </font>`<font style="color:rgb(31, 35, 41);">1</font>`<font style="color:rgb(31, 35, 41);">、</font>`<font style="color:rgb(31, 35, 41);">101</font>`<font style="color:rgb(31, 35, 41);">、</font>`<font style="color:rgb(31, 35, 41);">15</font>`<font style="color:rgb(31, 35, 41);"> 和 </font>`<font style="color:rgb(31, 35, 41);">2</font>`<font style="color:rgb(31, 35, 41);">，那么 </font>`<font style="color:rgb(31, 35, 41);">sort_by_label_numeric(foo, "bar")</font>`<font style="color:rgb(31, 35, 41);">会按 </font>`<font style="color:rgb(31, 35, 41);">bar</font>`<font style="color:rgb(31, 35, 41);"> 标签值的以下顺序返回序列：</font>`<font style="color:rgb(31, 35, 41);">1</font>`<font style="color:rgb(31, 35, 41);">、</font>`<font style="color:rgb(31, 35, 41);">2</font>`<font style="color:rgb(31, 35, 41);">、</font>`<font style="color:rgb(31, 35, 41);">15</font>`<font style="color:rgb(31, 35, 41);"> 和 </font>`<font style="color:rgb(31, 35, 41);">101</font>`<font style="color:rgb(31, 35, 41);">。</font>

另请参阅 [sort_by_label_numeric_desc](https://docs.victoriametrics.com/metricsql/#sort_by_label_numeric_desc) 和 [sort_by_label](https://docs.victoriametrics.com/metricsql/#sort_by_label).

### sort_by_label_numeric_desc
`sort_by_label_numeric`的反向操作，即降序排列。

