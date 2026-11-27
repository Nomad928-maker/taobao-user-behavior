-- 02_funnel_user.sql
-- 对应 notebook cell 8：用户级漏斗
--
-- 口径：9 天内只要有过该行为即计入该层，不要求行为间存在先后顺序。
-- 衡量的是「人群覆盖」，不是「访问路径」。单次访问的转化率见 03_funnel_session.sql。
--
-- 结果：users 987,991 / pv 984,105 / cart 738,996 / buy 672,404
--       pv2cart 75.09% / pv2buy 68.33% / cart2buy 90.99%

WITH u AS (
    SELECT user_id,
           MAX(CASE WHEN behavior_type = 'pv'   THEN 1 ELSE 0 END) AS has_pv,
           MAX(CASE WHEN behavior_type = 'cart' THEN 1 ELSE 0 END) AS has_cart,
           MAX(CASE WHEN behavior_type = 'fav'  THEN 1 ELSE 0 END) AS has_fav,
           MAX(CASE WHEN behavior_type = 'buy'  THEN 1 ELSE 0 END) AS has_buy
    FROM ub_clean
    GROUP BY 1
)
SELECT COUNT(*)                                        AS users,
       SUM(has_pv)                                     AS pv_users,
       SUM(has_cart)                                   AS cart_users,
       SUM(has_buy)                                    AS buy_users,
       ROUND(100.0 * SUM(has_cart) / SUM(has_pv), 2)   AS pv2cart,
       ROUND(100.0 * SUM(has_buy)  / SUM(has_pv), 2)   AS pv2buy,
       ROUND(100.0 * SUM(has_buy)  / SUM(has_cart), 2) AS cart2buy
FROM u;

-- 解读注意：68.33% 是这份「高活跃用户样本」的口径，不是淘宝真实转化率。
-- 真实电商的用户级转化率通常远低于此。
