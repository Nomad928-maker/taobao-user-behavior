# 原始数据（不入库）

把阿里天池「淘宝用户购物行为」数据集的 `UserBehavior.csv`（约 3.4 GB）放到本目录，即可复现全部分析：

```text
data/UserBehavior.csv
```

数据集说明：9 天观测窗口（2017-11-25 ~ 2017-12-03），约 1 亿条行为日志，字段为
`user_id, item_id, category_id, behavior_type, timestamp`，无表头。

因为体积过大，CSV 与生成的 `taobao.duckdb` 均在 `.gitignore` 中排除。
导入步骤见根目录 [README](../README.md) 第 6 节「复现」。
