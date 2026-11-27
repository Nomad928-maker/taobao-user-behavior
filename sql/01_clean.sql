-- 01_clean.sql
-- 对应 notebook cell 5-7：脏数据统计 + 清洗视图
--
-- 观测窗口：2017-11-25 00:00 ~ 2017-12-03 23:59（北京时间，UTC+8）
--   1511539200 = 2017-11-25 00:00 CST
--   1512316800 = 2017-12-04 00:00 CST
--
-- 口径修正：统一使用「左闭右开」区间 [1511539200, 1512316800)，
--           不要用 BETWEEN ... AND 1512316800（会把 12-04 00:00:00 那一秒算进来）。

-- ---------- 统计窗口外记录 ----------
-- 预期：bad_rows 54,751（占 0.0547%）
SELECT COUNT(*)                                                        AS bad_rows,
       ROUND(100.0 * COUNT(*) / (SELECT COUNT(*) FROM ub), 4)          AS pct
FROM ub
WHERE timestamp < 1511539200 OR timestamp >= 1512316800;

-- ---------- 清洗视图 ----------
-- 预期：100,095,898 行
CREATE OR REPLACE VIEW ub_clean AS
SELECT *
FROM ub
WHERE timestamp >= 1511539200
  AND timestamp <  1512316800;

SELECT COUNT(*) AS rows_clean FROM ub_clean;

-- ---------- 清洗后按天校验 ----------
-- 预期：9 行，11-25 至 12-03，每日 1000 万上下
-- 时间戳转换统一写法：make_timestamp(秒 × 1,000,000) + 8 小时
SELECT CAST(make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR AS DATE) AS dt,
       COUNT(*)                AS events,
       COUNT(DISTINCT user_id) AS dau
FROM ub_clean
GROUP BY 1
ORDER BY 1;
