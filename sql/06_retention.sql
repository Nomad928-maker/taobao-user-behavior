-- 06_retention.sql
-- 对应 notebook cell 12：日回访率
--
-- 为什么不用 cohort 留存：
--   数据只有 9 天窗口，且没有注册 / 首购事件。若用「首次出现在数据集里的日期」
--   建队列，99% 的用户都落在第一天（队列规模 706,641 -> 1），
--   得到的「留存衰减」是窗口边界造成的假象，不是用户行为。
--   因此退化为逐日回访率。
--
-- 边界处理：最后一天没有「次日」，必须排除，否则会得到接近 0 的假回访率。
--
-- 结果：11-25 ~ 11-30 稳定在 77.7% ~ 79.6%；
--       12-01 起跃升至 98%，同期 DAU 从 73 万涨到 97 万（接近全样本 98.8 万），
--       属采样边界效应，不构成行为结论。

WITH daily AS (
    SELECT DISTINCT user_id,
           CAST(make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR AS DATE) AS d
    FROM ub_clean
    WHERE timestamp >= 1511539200
      AND timestamp <  1512316800
)
SELECT a.d                                              AS dt,
       COUNT(DISTINCT a.user_id)                        AS dau,
       COUNT(DISTINCT b.user_id)                        AS next_day_users,
       ROUND(100.0 * COUNT(DISTINCT b.user_id)
             / COUNT(DISTINCT a.user_id), 2)            AS d1_return
FROM daily a
LEFT JOIN daily b
       ON a.user_id = b.user_id
      AND b.d = a.d + 1
WHERE a.d < (SELECT MAX(d) FROM daily)
GROUP BY 1
ORDER BY 1;

-- 如需 D2 / D3 回访率，把 b.d = a.d + 1 改成 + 2、+ 3 即可。
