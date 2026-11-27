-- 03_funnel_session.sql
-- 对应 notebook cell 13：会话级漏斗
--
-- 会话定义：同一用户相邻两次行为间隔 > 30 分钟（1800 秒）切分为新会话。
-- 该阈值属行业惯例，改成 15 或 60 分钟结论会变化，报告中需注明。
--
-- 结果：sessions 15,580,093 / buy_sessions 1,179,194 / pv2buy_session 7.57%
-- 对比：用户级 68.33%，相差约 9 倍——两个口径回答不同问题，不可混用。

WITH ev AS (
    SELECT user_id, timestamp, behavior_type,
           COALESCE(timestamp - LAG(timestamp) OVER (
               PARTITION BY user_id ORDER BY timestamp), 999999) AS gap
    FROM ub_clean
),
marked AS (
    SELECT *, CASE WHEN gap > 1800 THEN 1 ELSE 0 END AS new_sess
    FROM ev
),
sess AS (
    SELECT user_id, behavior_type,
           SUM(new_sess) OVER (PARTITION BY user_id ORDER BY timestamp
                               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS sid
    FROM marked
),
agg AS (
    SELECT user_id, sid,
           MAX(CASE WHEN behavior_type = 'pv'  THEN 1 ELSE 0 END) AS has_pv,
           MAX(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS has_buy
    FROM sess
    GROUP BY 1, 2
)
SELECT COUNT(*)                                        AS sessions,
       SUM(has_pv)                                     AS pv_sessions,
       SUM(has_buy)                                    AS buy_sessions,
       ROUND(100.0 * SUM(has_buy) / SUM(has_pv), 2)    AS pv2buy_session_pct
FROM agg
WHERE has_pv = 1;
