-------------------------------------------
-- 6. COHORT SUMMARY (TABLEAU SUPPORT VIEW)
-------------------------------------------

-- Goal:
-- Provide a clean cohort-level summary for Tableau dashboards.
-- This view isolates cohort size (Month 0 users) from the long-format table.

-- Notes:
-- cohort_month is converted from timestamp to DATE (month-level granularity)
-- to ensure correct aggregation and visualization in Tableau.

CREATE OR REPLACE VIEW analytics.cohort_summary AS
SELECT
    DATE_TRUNC('month', cohort_month)::date AS cohort_month,
    country,

    -- Cohort size = number of users in Month 0
    MAX(total_customers) FILTER (WHERE month_number = 0) AS cohort_size

FROM analytics.cohort_retention_long
GROUP BY cohort_month, country;