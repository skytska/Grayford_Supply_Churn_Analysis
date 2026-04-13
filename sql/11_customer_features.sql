------------------------------------------
-- 11. CUSTOMER FEATURES (PRODUCTION VIEW)
------------------------------------------

--- Goal:
-- Create a customer-level feature table for churn analysis in Python.

-- This view aggregates behavioral and value-based metrics from customers and orders tables.
-- It includes:
-- - RFM metrics (recency, frequency, monetary)
-- - Customer lifetime and tenure (in days)
-- - Average days between orders
-- - Recent activity (orders in last 30/60 days)
-- - Value segmentation (High / Mid / Low)
-- - Lifecycle segmentation (New / Active / Loyal / At-risk / Churned)

-- Grain: 1 row per customer_id

-- Note:
-- analysis_date is fixed as the latest available order date in the dataset.
-- This ensures consistency for recency and churn calculations.

-- - analytics.customer_features (final analytics table)
	
CREATE OR REPLACE VIEW analytics.customer_features AS

-- Aggregate order-level data to customer level (frequency, revenue, AOV)

WITH orders_agg AS (
SELECT
    customer_id,
    COUNT(order_id) AS frequency,
    ROUND(SUM(order_revenue), 2) AS monetary_usd,
    ROUND(AVG(order_revenue), 2) AS avg_order_value
FROM orders
GROUP BY customer_id
),

-- Define reference date (latest available order date) for recency/lifetime calculations

analysis_date AS (
    SELECT MAX(order_date)::date AS max_date FROM orders
),

-- Combine customer attributes with aggregated order metrics
-- and calculate core time-based features (lifetime, tenure, recency)

customer_base AS (
SELECT 
    c.customer_id,
    ad.max_date - c.first_purchase_date::date AS lifetime_days,
    c.last_purchase_date::date - c.first_purchase_date::date AS tenure_days,
    ad.max_date - c.last_purchase_date::date AS recency_days,
    oa.frequency,
    oa.monetary_usd,
    oa.avg_order_value
FROM customers c
JOIN orders_agg oa 
    ON c.customer_id = oa.customer_id
JOIN analysis_date ad 
    ON TRUE
),

-- Calculate time between consecutive orders for each customer

order_intervals AS (
SELECT 
	customer_id,
	order_date ::date AS order_date,
	LAG (order_date ::date) OVER (PARTITION BY customer_id
ORDER BY
	order_date) AS previous_order_date
FROM
	orders
),

-- Average number of days between orders per customer

avg_order_intervals AS (
SELECT 
	customer_id,
	AVG (order_date - previous_order_date)::int AS avg_days_between_orders
FROM
	order_intervals
GROUP BY
	customer_id
),

-- Count number of orders in the last 30 and 60 days

recent_orders AS (
SELECT
	o.customer_id,
	COUNT(o.order_id) FILTER (WHERE ad.max_date - o.order_date ::date <= 30) AS order_count_last_30d,
	COUNT(o.order_id) FILTER (WHERE ad.max_date - o.order_date ::date <= 60) AS order_count_last_60d
FROM
	orders o
JOIN analysis_date ad 
    ON TRUE
GROUP BY
	customer_id),
	
-- Rank customers by total revenue (monetary) to enable value segmentation
	
customer_percentiles  AS (
SELECT
	customer_id,
	monetary_usd,
	PERCENT_RANK() OVER (
	ORDER BY monetary_usd DESC) AS percentile_rank
FROM
	customer_base),
	
-- Assign value segments based on revenue percentiles:
	-- High-value: Top 30%
	-- Mid-value: Next 40%
	-- Low-value: Bottom 30%
	
value_segmentation AS(
SELECT 
	customer_id,
	CASE
		WHEN percentile_rank <= 0.3 THEN 'High-value'
    	WHEN percentile_rank <= 0.7 THEN 'Mid-value'
    ELSE 'Low-value' END AS value_segment
FROM customer_percentiles ),

-- Assign lifecycle stage and churn flag based on recency and tenure

lifecycle_segments  AS (
SELECT
	customer_id,
	CASE
		WHEN recency_days > 90 THEN 'Churned'
	    WHEN tenure_days <= 30 THEN 'New'
	    WHEN tenure_days > 90 AND recency_days <= 30 THEN 'Loyal'
	    WHEN tenure_days > 30 AND recency_days <= 30 THEN 'Active'
	    WHEN recency_days > 30 THEN 'At-risk'
	END AS lifecycle_segment,
	CASE
		WHEN recency_days > 90 THEN 1
		ELSE 0
	END AS is_churned
FROM
	customer_base)

SELECT
	cb.*,
	oi.avg_days_between_orders,
	ro.order_count_last_30d,
	ro.order_count_last_60d,
	vs.value_segment,
	ls.lifecycle_segment,
	ls.is_churned
FROM
	customer_base cb
LEFT JOIN avg_order_intervals oi
ON cb.customer_id = oi.customer_id
LEFT JOIN recent_orders  ro
ON cb.customer_id = ro.customer_id
LEFT JOIN value_segmentation vs
ON cb.customer_id = vs.customer_id
LEFT JOIN lifecycle_segments   ls
ON cb.customer_id = ls.customer_id


