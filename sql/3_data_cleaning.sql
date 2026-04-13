--------------------
-- 3. DATA CLEANING --
--------------------

-- Create clean_transactions table
-- Grain: 1 row = 1 item in a transaction (line-level data)

-- Data cleaning steps:
-- 1. Remove exact duplicate rows using DISTINCT
--    (Note: this is not business-rule deduplication.
--     In production systems, duplicate handling may involve window functions and business keys)
-- 2. Remove rows with missing customer_id (cannot be used for customer-level analysis)
-- 3. Normalize column names and cast data types to proper formats
-- 4. Parse invoice_date from text to timestamp (note: assumes all invoicedate values follow 'DD.MM.YYYY HH24:MI' format).
-- 5. Create derived metric: item_transaction_revenue = quantity * unit_price
-- 6. Classify transactions:
--    - quantity < 0 → RETURN
--    - quantity >= 0 → PURCHASE


CREATE TABLE clean_transactions AS
SELECT DISTINCT
    invoiceno AS invoice_no,
	stockcode AS stock_code,
	description,
	quantity,
  	to_timestamp(invoicedate, 'DD.MM.YYYY HH24:MI') AS invoice_date,
	unitprice AS unit_price,
	customerid AS customer_id,
	country,
    ROUND(quantity * unitprice, 2) AS item_transaction_revenue,
    CASE
		WHEN quantity < 0 THEN 'RETURN'
		ELSE 'PURCHASE'
	END AS transaction_type
FROM
	public.onlineretail
WHERE
	customerid IS NOT NULL;

-- Create orders table
-- Grain: 1 row = 1 order (order-level data) 

-- What this table enables:
-- ✔ Correct revenue aggregation (no duplication at item level)
-- ✔ Calculation of key metrics:
--     - AOV (Average Order Value)
--     - Orders per customer
--     - Revenue trends
-- ✔ Simplified cohort and retention analysis

CREATE TABLE orders AS
SELECT
    invoice_no AS order_id,
    customer_id,
    MIN(invoice_date) AS order_date,
    DATE_TRUNC('month', MIN(invoice_date))::date AS order_month,
    SUM(item_transaction_revenue) AS order_revenue,
    CASE 
        WHEN SUM(CASE WHEN quantity < 0 THEN 1 ELSE 0 END) > 0 THEN 'Y'
        ELSE 'N'
    END AS is_return,
    country
FROM clean_transactions
GROUP BY 
    invoice_no,
    customer_id,
    country;

-- Create customers table
-- Grain: 1 row = 1 customer (user-level data) 

-- What this table enables:
-- ✔ Customer-level analytics:
--     - Lifetime / tenure
--     - Retention & churn analysis
--     - LTV (lifetime value)
-- ✔ Advanced analysis:
--     - Survival curves
--     - RFM segmentation

CREATE TABLE customers AS
SELECT 
    customer_id,
    MIN(invoice_date) AS first_purchase_date,
    DATE_TRUNC('month', MIN(invoice_date))::date AS cohort_month,
    MAX(invoice_date) AS last_purchase_date,
    COUNT(DISTINCT invoice_no) AS total_orders,
    SUM(item_transaction_revenue) AS total_revenue
FROM clean_transactions
GROUP BY customer_id;


	
	
	
	
	