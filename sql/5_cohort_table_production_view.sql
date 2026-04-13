-------------------------------------
-- 5. COHORT TABLE (PRODUCTION VIEWS)
-------------------------------------

-- Goal:
-- Provide clean, reusable datasets for Tableau:
-- - analytics.cohort_analysis_base (base layer)
-- - analytics.cohort_retention_long (final analytics table)

CREATE OR REPLACE VIEW analytics.cohort_retention_long AS
WITH customer_activity AS (
    SELECT 
        cab.customer_id,
        cab.cohort_month,
        cab.country,
        cab.order_month,
        cab.order_revenue,
        (
            EXTRACT(YEAR FROM cab.order_month) * 12 + EXTRACT(MONTH FROM cab.order_month)
            -
            (EXTRACT(YEAR FROM cab.cohort_month) * 12 + EXTRACT(MONTH FROM cab.cohort_month))
        ) AS month_number
    FROM
        analytics.cohort_analysis_base cab
    WHERE 
        cab.order_month >= cab.cohort_month
),

cohort_activity AS (
    SELECT 
        cohort_month,
        country,
        month_number,
        COUNT(DISTINCT customer_id) AS active_customers,
        SUM(order_revenue) AS total_revenue
    FROM
        customer_activity
    GROUP BY
        cohort_month,
        country,
        month_number
),

cohort_size AS (
    SELECT 
        cohort_month,
        country,
        COUNT(DISTINCT customer_id) AS total_customers,
        SUM(order_revenue) AS base_revenue
    FROM
        customer_activity
    WHERE 
        month_number = 0
    GROUP BY 
        cohort_month,
        country
)

SELECT 
    ca.cohort_month,
    ca.country,
    ca.month_number,

    -- Base metrics
    ca.active_customers,
    cs.total_customers,
    ca.total_revenue,
    cs.base_revenue,

    -- User retention
    ROUND(ca.active_customers * 1.0 / NULLIF (cs.total_customers,0), 4) AS retention_users,

    -- Revenue retention
    ROUND(ca.total_revenue * 1.0 / NULLIF(cs.base_revenue,0), 4) AS retention_revenue,

    -- AOV
    ROUND(ca.total_revenue * 1.0 / NULLIF(ca.active_customers,0), 2) AS avg_order_value

FROM
    cohort_activity ca
LEFT JOIN cohort_size cs
    ON ca.cohort_month = cs.cohort_month
    AND ca.country = cs.country

ORDER BY
    ca.cohort_month,
    ca.month_number;

SELECT *
FROM analytics.cohort_retention_long

------------------------------------------------------------
-- Notes:
--
-- 1. analytics.cohort_retention_long is the main dataset for Tableau
--
-- 2. Suggested Tableau setup:
--    Rows: cohort_month
--    Columns: month_number
--    Color: retention_users / retention_revenue
--
-- 3. This dataset supports segmentation by country
--
-- 4. Additional metrics available:
--    - revenue retention
--    - AOV (avg_order_value)
--
------------------------------------------------------------