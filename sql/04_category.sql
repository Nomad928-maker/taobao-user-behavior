-- 04_category.sql
-- 对应 notebook cell 9：品类维度的流量与转化
--
-- 口径：用户级（9 天内浏览过该品类的用户 vs 购买过该品类的用户）
-- 阈值：只保留浏览用户 >= 5,000 的品类，避免小样本噪声
--
-- 发现：cvr 从 1.39% 到 18.28%，相差 13 倍；
--       而 pv_share 集中在 0.6% ~ 1.8%，说明流量分配与转化效率基本无关。
-- 注意：本数据无金额字段，cvr 只反映人群覆盖效率，不代表 GMV 贡献。

WITH c AS (
    SELECT category_id, user_id,
           MAX(CASE WHEN behavior_type = 'pv'  THEN 1 ELSE 0 END) AS pv_u,
           MAX(CASE WHEN behavior_type = 'buy' THEN 1 ELSE 0 END) AS buy_u
    FROM ub_clean
    GROUP BY 1, 2
)
SELECT category_id,
       SUM(pv_u)                                                    AS pv_users,
       SUM(buy_u)                                                   AS buy_users,
       ROUND(100.0 * SUM(buy_u) / SUM(pv_u), 2)                     AS cvr,
       ROUND(100.0 * SUM(pv_u) / (SELECT SUM(pv_u) FROM c), 3)      AS pv_share
FROM c
GROUP BY 1
HAVING SUM(pv_u) >= 5000
ORDER BY pv_users DESC
LIMIT 20;

-- 解读：
--   高 pv_share + 低 cvr -> 流量浪费，优化详情页 / 价格 / 选品
--   低 pv_share + 高 cvr -> 潜力品类，可加流量测试
