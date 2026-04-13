-----------------------------------------------------
-- 11. CHURN RETURN CURVE (TABLEAU SUPPORT VIEW)
-----------------------------------------------------

-- Goal:
-- Provide a dataset for visualizing customer return behavior over time.
-- This view supports churn threshold analysis in Tableau.

-- Business Context:
-- The return curve represents the cumulative probability that a customer
-- places a repeat order after X days since their previous purchase.

-- Key Insight:
-- The curve typically plateaus around ~90 days, supporting the definition
-- of churn as inactivity for 90+ days.

-- Why this view is needed:
-- The raw orders table is at transaction level.
-- This view aggregates it into a clean format suitable for visualization.

CREATE OR REPLACE VIEW analytics.churn_return_curve AS

WITH order_intervals AS (
    SELECT 
        (
            LEAD(order_date) OVER (PARTITION BY customer_id ORDER BY order_date)::date 
            - order_date::date
        ) AS days_between_orders
    FROM public.orders
),

intervals_clean AS (
    SELECT days_between_orders
    FROM order_intervals
    WHERE days_between_orders IS NOT NULL
),

interval_distribution AS (
    SELECT
        days_between_orders,
        COUNT(*) AS orders_count
    FROM intervals_clean
    GROUP BY days_between_orders
),

return_curve AS (
    SELECT
        days_between_orders,
        SUM(orders_count) OVER (ORDER BY days_between_orders)::float
        / SUM(orders_count) OVER () AS return_probability
    FROM interval_distribution
)

SELECT * FROM return_curve;