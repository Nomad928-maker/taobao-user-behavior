-- 07_rfm.sql
-- 用途：RFM 用户价值分层（本数据无金额字段，只做 R 与 F）
--
-- 口径说明：
--   R（Recency）：距观测窗口结束日（2017-12-04）的天数，用 NTILE(5) 反向打分，
--                 最近购买 = 5 分，最久未买 = 1 分。
--   F（Frequency）：购买行为条数（COUNT(*)），用 NTILE(5) 打分，买得越多分越高。
--   M（Money）：数据无金额字段，不做。
--   rf_score = r_score + f_score，取值 2 ~ 10，越高代表「越近买、买得越多」。
--
-- ⚠️ 限制：观测窗口只有 9 天，r_days 取值被截断在 0~9，
--          5 档中每档不足 2 天，分层仅作方法演示，不足以支撑真实的生命周期运营。
-- ⚠️ F 的口径：COUNT(*) 数的是购买行为条数，不是订单数；
--          若一次下单含多件商品，F 会高估购买频次。

WITH base AS (
    SELECT user_id,
           MAX(CAST(make_timestamp(timestamp * 1000000) + INTERVAL 8 HOUR AS DATE)) AS last_buy,
           COUNT(*) AS f
    FROM ub_clean
    WHERE behavior_type = 'buy'
    GROUP BY 1
),
scored AS (
    SELECT user_id,
           last_buy,
           f,
           DATE '2017-12-04' - last_buy        AS r_days,
           NTILE(5) OVER (ORDER BY last_buy)   AS r_score,  -- 越近分越高
           NTILE(5) OVER (ORDER BY f)          AS f_score   -- 越多分越高
    FROM base
)
SELECT user_id,
       last_buy,
       r_days,
       f,
       r_score,
       f_score,
       r_score + f_score AS rf_score
FROM scored
ORDER BY rf_score DESC, r_days
LIMIT 10;

-- ---------- 可选：看 rf_score 的人群分布 ----------
-- 把上面 LIMIT 10 换成下面的聚合，可以看出用户集中在哪个分值段：
--
-- SELECT rf_score, COUNT(*) AS users,
--        ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct
-- FROM (
--     SELECT r_score + f_score AS rf_score
--     FROM scored
-- ) t
-- GROUP BY 1
-- ORDER BY 1;
