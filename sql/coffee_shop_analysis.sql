-- Coffee Shop Sales Analysis
-- Tools: SQLite, Power BI
-- Purpose: Clean, explore, and analyze coffee shop sales data
-- Note: Queries are selected from the SQL used during the project and cleaned for readability.

-- =====================================================
-- 1. DATA OVERVIEW
-- =====================================================

-- 1.1 Dataset overview
SELECT
    COUNT(*) AS total_transactions,
    COUNT(DISTINCT store_id) AS total_stores,
    MIN(transaction_date) AS first_transaction_date,
    MAX(transaction_date) AS last_transaction_date,
    SUM(transaction_qty) AS total_quantity,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales";


-- =====================================================
-- 2. DATA CLEANING
-- =====================================================

-- 2.1 Create a standardized date column
-- Run ALTER TABLE only once.
ALTER TABLE "Coffee Shop Sales"
ADD COLUMN clean_date TEXT;

-- Convert transaction_date from M/D/YYYY format to YYYY-MM-DD
UPDATE "Coffee Shop Sales"
SET clean_date = printf(
    '%04d-%02d-%02d',
    CAST(substr(transaction_date, -4) AS INTEGER),
    CAST(transaction_date AS INTEGER),
    CAST(
        substr(
            transaction_date,
            instr(transaction_date, '/') + 1
        ) AS INTEGER
    )
);

-- Validate the converted dates
SELECT
    transaction_date,
    clean_date
FROM "Coffee Shop Sales"
LIMIT 10;


-- =====================================================
-- 3. SALES TREND ANALYSIS
-- =====================================================

-- 3.1 Monthly revenue trend
SELECT
    strftime('%m', clean_date) AS month,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales"
GROUP BY month
ORDER BY month;


-- 3.2 Average daily revenue by month
SELECT
    month,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
FROM (
    SELECT
        strftime('%m', clean_date) AS month,
        clean_date,
        SUM(unit_price * transaction_qty) AS daily_revenue
    FROM "Coffee Shop Sales"
    GROUP BY month, clean_date
) AS daily_sales
GROUP BY month
ORDER BY month;


-- =====================================================
-- 4. STORE PERFORMANCE
-- =====================================================

-- 4.1 Overall revenue and quantity by store
SELECT
    store_location,
    SUM(transaction_qty) AS total_quantity,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales"
GROUP BY store_location
ORDER BY total_revenue DESC;


-- 4.2 Monthly store performance
SELECT
    strftime('%m', clean_date) AS month,
    store_location,
    SUM(transaction_qty) AS total_quantity,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales"
GROUP BY month, store_location
ORDER BY month, total_revenue DESC;


-- =====================================================
-- 5. PRODUCT PERFORMANCE
-- =====================================================

-- 5.1 Revenue and quantity by product category
SELECT
    product_category,
    SUM(transaction_qty) AS total_quantity,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales"
GROUP BY product_category
ORDER BY total_revenue DESC;


-- 5.2 Top 5 product types by revenue
SELECT
    product_type,
    SUM(transaction_qty) AS total_quantity,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue
FROM "Coffee Shop Sales"
GROUP BY product_type
ORDER BY total_revenue DESC
LIMIT 5;


-- 5.3 Average unit price by product category
SELECT
    product_category,
    ROUND(AVG(unit_price), 2) AS avg_unit_price
FROM "Coffee Shop Sales"
GROUP BY product_category
ORDER BY avg_unit_price DESC;


-- 5.4 Classify product types by revenue level
SELECT
    product_type,
    ROUND(SUM(unit_price * transaction_qty), 2) AS total_revenue,
    CASE
        WHEN SUM(unit_price * transaction_qty) >= 30000 THEN 'High Revenue'
        WHEN SUM(unit_price * transaction_qty) >= 15000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_level
FROM "Coffee Shop Sales"
GROUP BY product_type
ORDER BY total_revenue DESC;


-- =====================================================
-- 6. WEEKDAY VS WEEKEND ANALYSIS
-- =====================================================

-- 6.1 Average daily revenue: Weekday vs Weekend
SELECT
    day_type,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
FROM (
    SELECT
        clean_date,
        CASE
            WHEN strftime('%w', clean_date) IN ('0', '6') THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        SUM(unit_price * transaction_qty) AS daily_revenue
    FROM "Coffee Shop Sales"
    GROUP BY clean_date
) AS daily_sales
GROUP BY day_type;


-- 6.2 Monthly average daily revenue: Weekday vs Weekend
SELECT
    month,
    day_type,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
FROM (
    SELECT
        strftime('%m', clean_date) AS month,
        clean_date,
        CASE
            WHEN strftime('%w', clean_date) IN ('0', '6') THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        SUM(unit_price * transaction_qty) AS daily_revenue
    FROM "Coffee Shop Sales"
    GROUP BY month, clean_date
) AS daily_sales
GROUP BY month, day_type
ORDER BY month, day_type;


-- 6.3 June product-category mix: Weekday vs Weekend
SELECT
    day_type,
    product_category,
    ROUND(AVG(daily_revenue), 2) AS avg_daily_revenue
FROM (
    SELECT
        clean_date,
        product_category,
        CASE
            WHEN strftime('%w', clean_date) IN ('0', '6') THEN 'Weekend'
            ELSE 'Weekday'
        END AS day_type,
        SUM(unit_price * transaction_qty) AS daily_revenue
    FROM "Coffee Shop Sales"
    WHERE strftime('%m', clean_date) = '06'
    GROUP BY clean_date, product_category
) AS daily_category_sales
GROUP BY day_type, product_category
ORDER BY day_type, avg_daily_revenue DESC;
