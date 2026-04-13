--------------------
-- 4. COHORT TABLE (EXPLORATION)
--------------------

-- Goal:
-- Build cohort retention tables to analyze:
-- - User retention
-- - Revenue retention
-- - Customer behavior (AOV)

------------------------------------------------------------
-- 0. Ensure analytics schema exists
------------------------------------------------------------

CREATE SCHEMA IF NOT EXISTS analytics;

------------------------------------------------------------
-- 1. Base VIEW: customer activity with cohort info
------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.cohort_analysis_base AS
SELECT 
    c.customer_id,
    c.cohort_month,
    o.country,
    o.order_month,
    o.order_revenue
FROM
    public.customers c
INNER JOIN public.orders o 
    ON c.customer_id = o.customer_id
WHERE 
    o.order_month IS NOT NULL;

------------------------------------------------------------
-- 2. Cohort calculation pipeline (for exploration)
------------------------------------------------------------

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

------------------------------------------------------------
-- 3. Pivot table (optional check)
------------------------------------------------------------

SELECT 
    ca.cohort_month,
    ca.country,
    cs.total_customers,

    ROUND(MAX(CASE WHEN ca.month_number = 0 THEN ca.active_customers * 1.0 / cs.total_customers END), 2) AS retention_m0,
    ROUND(MAX(CASE WHEN ca.month_number = 1 THEN ca.active_customers * 1.0 / cs.total_customers END), 2) AS retention_m1,
    ROUND(MAX(CASE WHEN ca.month_number = 2 THEN ca.active_customers * 1.0 / cs.total_customers END), 2) AS retention_m2,
    ROUND(MAX(CASE WHEN ca.month_number = 3 THEN ca.active_customers * 1.0 / cs.total_customers END), 2) AS retention_m3

FROM
    cohort_activity ca
LEFT JOIN cohort_size cs
    ON ca.cohort_month = cs.cohort_month
    AND ca.country = cs.country

GROUP BY
    ca.cohort_month,
    ca.country,
    cs.total_customers

ORDER BY
    ca.cohort_month,
    ca.country;