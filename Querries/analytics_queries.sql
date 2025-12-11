-- ===========================================================
-- CustoVision Project
-- ANALYTICS & BI QUERIES
-- Purpose: KPI calculations, forecasting insights, trends
-- ===========================================================

---------------------------------------------------------------
-- 1. Monthly sales revenue trend
---------------------------------------------------------------
SELECT
    TO_CHAR(sale_date, 'YYYY-MM') AS month,
    SUM(quantity_sold * unit_price_sold) AS monthly_revenue
FROM sales_history
GROUP BY TO_CHAR(sale_date, 'YYYY-MM')
ORDER BY month;


---------------------------------------------------------------
-- 2. Top 10 products by total revenue
---------------------------------------------------------------
SELECT
    p.product_name,
    SUM(sh.quantity_sold) AS total_units_sold,
    SUM(sh.quantity_sold * sh.unit_price_sold) AS total_revenue
FROM sales_history sh
JOIN products p ON sh.product_id = p.product_id
GROUP BY p.product_name
ORDER BY total_revenue DESC
FETCH FIRST 10 ROWS ONLY;


---------------------------------------------------------------
-- 3. Stockout risk: products below safety threshold
---------------------------------------------------------------
SELECT
    product_id,
    product_name,
    current_stock,
    CASE 
        WHEN current_stock < 20 THEN 'HIGH RISK'
        WHEN current_stock BETWEEN 20 AND 50 THEN 'MEDIUM RISK'
        ELSE 'SAFE'
    END AS stock_risk
FROM products
ORDER BY current_stock ASC;


---------------------------------------------------------------
-- 4. Forecast accuracy assessment (if actual exists)
---------------------------------------------------------------
SELECT
    f.product_id,
    p.product_name,
    f.forecast_amount,
    SUM(sh.quantity_sold) AS actual_sales,
    ROUND(
        (SUM(sh.quantity_sold) - f.forecast_amount) / NULLIF(f.forecast_amount, 0), 
        2
    ) AS error_rate
FROM forecasts f
LEFT JOIN products p ON f.product_id = p.product_id
LEFT JOIN sales_history sh 
    ON f.product_id = sh.product_id
    AND sh.sale_date BETWEEN f.forecast_period_start AND f.forecast_period_end
GROUP BY f.product_id, p.product_name, f.forecast_amount;


---------------------------------------------------------------
-- 5. Customer segmentation overview
---------------------------------------------------------------
SELECT
    segment_label,
    COUNT(*) AS total_customers,
    ROUND(AVG(segment_score), 2) AS avg_score
FROM customer_segments
GROUP BY segment_label
ORDER BY total_customers DESC;
