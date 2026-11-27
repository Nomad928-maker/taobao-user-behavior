-- 05_time_of_day.sql
-- 对应 notebook cell 10-11：时段分析
--
-- 三个注意点：
--   1. 必须 +8 小时转北京时间，否则峰值整体偏移 8 小时
--   2. buy_pct 是「事件中购买行为的占比」，不等于用户转化率
--   3. 量的峰值和率的峰值不同：量在 21 点，率在 10 点
--
-- 结果：事件量峰值 21 点（837 万），buy_pct 峰值 10 点（2.62%）
--       绝对下单量峰值仍在 21 点（约 14.6 万单）

-- ---------- 基础版：按小时 ----------
SELECT EXTRACT(HOUR FROM make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR) AS hr,
       COUNT(*)                                                      AS events,
       COUNT(DISTINCT user_id)                                       AS users,
       ROUND(100.0 * SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END)
             / COUNT(*), 2)                                          AS buy_pct
FROM ub_clean
GROUP BY hr
ORDER BY hr;

-- ---------- 进阶版：区分工作日 / 周末 ----------
-- 9 天中含 4 个周末（11-25、11-26、12-02、12-03），时段结构不同，建议分开看。
-- ISODOW：1=周一 … 6=周六、7=周日
SELECT EXTRACT(HOUR FROM make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR) AS hr,
       CASE WHEN EXTRACT(ISODOW FROM make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR) >= 6
            THEN '周末' ELSE '工作日' END                            AS day_type,
       COUNT(*)                                                      AS events,
       SUM(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END)        AS buys
FROM ub_clean
GROUP BY 1, 2
ORDER BY 2, 1;
