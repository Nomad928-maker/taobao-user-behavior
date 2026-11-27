-- 00_load.sql
-- 对应 notebook cell 2-4：建表 + 基础校验
--
-- 数据：UserBehavior.csv（1 亿行，无表头，5 列，约 3.4 GB）
-- 运行：duckdb taobao.duckdb < sql/00_load.sql

-- ---------- 建表 ----------
CREATE OR REPLACE TABLE ub AS
SELECT * FROM read_csv_auto('data/UserBehavior.csv', header = false,
    columns = {'user_id':       'BIGINT',
               'item_id':       'BIGINT',
               'category_id':   'BIGINT',
               'behavior_type': 'VARCHAR',
               'timestamp':     'BIGINT'});

-- ---------- 校验：行数 / 基数 / 值域 ----------
-- 预期：rows 100,150,807 / users 987,994 / items 4,162,024
-- 注意：ts_min 与 ts_max 会显示越界值（-2.13e9 / 2.12e9），说明原始数据含脏行
SELECT COUNT(*)                AS rows,
       COUNT(DISTINCT user_id) AS users,
       COUNT(DISTINCT item_id) AS items,
       MIN(timestamp)          AS ts_min,
       MAX(timestamp)          AS ts_max
FROM ub;

-- ---------- 行为分布 ----------
-- 预期：pv 约 90%、cart 约 5.5%、fav 约 2.9%、buy 约 2.0%
SELECT behavior_type,
       COUNT(*)                                             AS cnt,
       ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)   AS pct
FROM ub
GROUP BY 1
ORDER BY cnt DESC;
