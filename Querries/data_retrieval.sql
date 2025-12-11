-- ===========================================================
-- CustoVision Project
-- DATA RETRIEVAL QUERIES
-- Purpose: Frequently used SELECTs across the system
-- ===========================================================


--------------------------------------------------------------
-- 1. Retrieve all products with current stock & category
---------------------------------------------------------------
SELECT 
    product_id,
    product_name,
    category,
    unit_price,
    current_stock
FROM products
ORDER BY product_name;


---------------------------------------------------------------
-- 2. Retrieve all customers with segmentation if available
---------------------------------------------------------------
SELECT 
    c.customer_id,
    c.customer_name,
    c.email,
    c.city,
    c.country,
    cs.segment_label,
    cs.segment_score
FROM customers c
LEFT JOIN customer_segments cs 
    ON c.customer_id = cs.customer_id;


---------------------------------------------------------------
-- 3. Retrieve complete sales transactions
---------------------------------------------------------------
SELECT
    sh.sale_id,
    sh.sale_date,
    p.product_name,
    c.customer_name,
    sh.quantity_sold,
    sh.unit_price_sold,
    (sh.quantity_sold * sh.unit_price_sold) AS total_sale_value
FROM sales_history sh
LEFT JOIN products p  ON sh.product_id = p.product_id
LEFT JOIN customers c ON sh.customer_id = c.customer_id
ORDER BY sh.sale_date DESC;


---------------------------------------------------------------
-- 4. Retrieve inventory movements per product
---------------------------------------------------------------
SELECT
    it.inv_txn_id,
    it.product_id,
    p.product_name,
    it.txn_type,
    it.quantity,
    it.txn_date
FROM inventory_transactions it
JOIN products p ON it.product_id = p.product_id
ORDER BY it.txn_date DESC;


---------------------------------------------------------------
-- 5. Retrieve all active alerts
---------------------------------------------------------------
SELECT 
    a.alert_id,
    p.product_name,
    a.alert_date,
    a.recommended_qty,
    a.alert_reason,
    a.acknowledged
FROM alerts a
JOIN products p ON a.product_id = p.product_id
ORDER BY a.alert_date DESC;

--Verify audit log:
SELECT username, action_type, allowed, reason, log_date
FROM audit_log
ORDER BY log_date DESC;
--User Info Correctly Recorded
SELECT username,
       action_type,
       allowed,
       reason,
       TO_CHAR(log_date, 'YYYY-MM-DD HH24:MI:SS') AS log_time
FROM audit_log
ORDER BY log_date DESC;

--viewing all customers 
select * from customers