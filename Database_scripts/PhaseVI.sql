--A. Support: Error Log Table (for exception handling)
Create this first (used by procedures to log errors).
CREATE TABLE error_log (
  err_id        NUMBER PRIMARY KEY,
  err_timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
  err_source    VARCHAR2(100),
  err_code      VARCHAR2(50),
  err_message   VARCHAR2(4000),
  err_stack     CLOB
);

-- sequence and trigger for error_log
CREATE SEQUENCE seq_err START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

CREATE OR REPLACE TRIGGER trg_err_pk BEFORE INSERT ON error_log
FOR EACH ROW
BEGIN
  :NEW.err_id := seq_err.NEXTVAL;
END;
/

--B. Procedures (5) — with IN / OUT / IN OUT, DML, and exception handling
--1) proc_insert_product — adds a product (IN parameters)
CREATE OR REPLACE PROCEDURE proc_insert_product(
  p_name      IN  VARCHAR2,
  p_category  IN  VARCHAR2,
  p_price     IN  NUMBER,
  p_stock     IN  NUMBER,
  p_out_id    OUT NUMBER
) IS
BEGIN
  INSERT INTO products(product_name, category, unit_price, current_stock)
  VALUES (p_name, p_category, p_price, p_stock)
  RETURNING product_id INTO p_out_id;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_insert_product', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_insert_product;
/
--2) proc_update_stock_after_sale — adjusts product stock (IN) and logs update (IN OUT example)
CREATE OR REPLACE PROCEDURE proc_update_stock_after_sale(
  p_product_id IN NUMBER,
  p_qty_sold   IN NUMBER,
  p_new_stock  OUT NUMBER
) IS
  v_stock NUMBER;
BEGIN
  SELECT current_stock INTO v_stock FROM products WHERE product_id = p_product_id FOR UPDATE;
  v_stock := v_stock - p_qty_sold;
  IF v_stock < 0 THEN
    -- enforce business rule: cannot have negative stock
    RAISE_APPLICATION_ERROR(-20001, 'Insufficient stock for product ' || p_product_id);
  END IF;
  UPDATE products SET current_stock = v_stock WHERE product_id = p_product_id;
  p_new_stock := v_stock;
  COMMIT;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    INSERT INTO error_log(err_source, err_code, err_message) VALUES('proc_update_stock_after_sale','NO_DATA_FOUND','Product not found: '||p_product_id);
    RAISE;
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_update_stock_after_sale', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_update_stock_after_sale;
/
--3) proc_record_sale — inserts a sale and updates stock (IN parameters), demonstrates transaction control
CREATE OR REPLACE PROCEDURE proc_record_sale(
  p_product_id    IN NUMBER,
  p_customer_id   IN NUMBER,
  p_sale_date     IN DATE,
  p_quantity      IN NUMBER,
  p_unit_price    IN NUMBER,
  p_out_sale_id   OUT NUMBER
) IS
BEGIN
  -- Start a transaction: insert sale, then update stock
  INSERT INTO sales_history(product_id, customer_id, sale_date, quantity_sold, unit_price_sold)
  VALUES (p_product_id, p_customer_id, p_sale_date, p_quantity, p_unit_price)
  RETURNING sale_id INTO p_out_sale_id;

  -- Update stock using the earlier proc
  DECLARE v_new_stock NUMBER;
  BEGIN
    proc_update_stock_after_sale(p_product_id, p_quantity, v_new_stock);
  EXCEPTION
    WHEN OTHERS THEN
      -- If stock update fails, roll back sale too
      RAISE;
  END;

  -- Optionally write decision log or audit
  INSERT INTO decision_log(actor, decision_type, data_payload)
  VALUES ('SYSTEM', 'SALE_RECORD', 'sale_id='||p_out_sale_id||';prod='||p_product_id||';qty='||p_quantity);

  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_record_sale', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_record_sale;
/
--4) proc_generate_alerts_for_low_stock — scans forecasts and products, inserts alerts (cursor-based)
CREATE OR REPLACE PROCEDURE proc_generate_alerts_for_low_stock IS
  CURSOR c_low IS
    SELECT f.forecast_id, f.product_id, f.forecast_amount, p.current_stock
    FROM forecasts f
    JOIN products p ON p.product_id = f.product_id
    WHERE f.forecast_period_start >= TRUNC(SYSDATE);
  v_rec c_low%ROWTYPE;
BEGIN
  OPEN c_low;
  LOOP
    FETCH c_low INTO v_rec;
    EXIT WHEN c_low%NOTFOUND;
    IF v_rec.forecast_amount > v_rec.current_stock THEN
      INSERT INTO alerts(product_id, forecast_id, recommended_qty, alert_reason)
      VALUES (v_rec.product_id, v_rec.forecast_id, (v_rec.forecast_amount - v_rec.current_stock), 'Forecast > stock');
    END IF;
  END LOOP;
  CLOSE c_low;
  COMMIT;
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_generate_alerts_for_low_stock', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_generate_alerts_for_low_stock;
/
--5) proc_apply_recommended_reorder — example of IN OUT and conditional auto-approve
CREATE OR REPLACE PROCEDURE proc_apply_recommended_reorder(
  p_alert_id    IN  NUMBER,
  p_auto_approve IN OUT CHAR
) IS
  v_product_id NUMBER;
  v_qty        NUMBER;
  v_ack CHAR(1);
BEGIN
  SELECT product_id, recommended_qty, acknowledged INTO v_product_id, v_qty, v_ack
  FROM alerts WHERE alert_id = p_alert_id FOR UPDATE;

  IF p_auto_approve = 'Y' AND v_qty <= 100 THEN
    -- Simulate creating order: insert inventory txn as RECEIPT and update stock
    INSERT INTO inventory_transactions(product_id, quantity, txn_type) VALUES (v_product_id, v_qty, 'RECEIPT');
    UPDATE products SET current_stock = current_stock + v_qty WHERE product_id = v_product_id;
    UPDATE alerts SET acknowledged='Y' WHERE alert_id = p_alert_id;
    COMMIT;
  ELSE
    -- leave for manager review
    p_auto_approve := 'N';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_apply_recommended_reorder', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_apply_recommended_reorder;
/

--C. Functions (5) — calculation/validation/lookup with return types
1) fn_calculate_reorder_qty — calculation function (returns NUMBER)
CREATE OR REPLACE FUNCTION fn_calculate_reorder_qty(
  p_product_id IN NUMBER,
  p_forecast_periods IN NUMBER DEFAULT 1,
  p_safety_stock IN NUMBER DEFAULT 10
) RETURN NUMBER IS
  v_forecast_sum NUMBER;
  v_current_stock NUMBER;
BEGIN
  SELECT NVL(SUM(forecast_amount),0) INTO v_forecast_sum
  FROM forecasts
  WHERE product_id = p_product_id
    AND forecast_period_start >= TRUNC(SYSDATE)
    AND ROWNUM <= p_forecast_periods;

  SELECT current_stock INTO v_current_stock FROM products WHERE product_id = p_product_id;

  RETURN GREATEST(0, ROUND(v_forecast_sum - v_current_stock + p_safety_stock));
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 0;
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('fn_calculate_reorder_qty', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 0;
END fn_calculate_reorder_qty;
/
--2) fn_validate_email — validation function (returns BOOLEAN)
CREATE OR REPLACE FUNCTION fn_validate_email(p_email IN VARCHAR2) RETURN VARCHAR2 IS
BEGIN
  IF p_email IS NULL THEN
    RETURN 'NULL';
  ELSIF REGEXP_LIKE(p_email, '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$') THEN
    RETURN 'VALID';
  ELSE
    RETURN 'INVALID';
  END IF;
EXCEPTION
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('fn_validate_email', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 'ERROR';
END fn_validate_email;
/
--3) fn_get_product_price — lookup function (returns NUMBER)
CREATE OR REPLACE FUNCTION fn_get_product_price(p_product_id IN NUMBER) RETURN NUMBER IS
  v_price NUMBER;
BEGIN
  SELECT unit_price INTO v_price FROM products WHERE product_id = p_product_id;
  RETURN v_price;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN NULL;
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('fn_get_product_price', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN NULL;
END fn_get_product_price;
/
--4) fn_total_sales_last_n_days — aggregate function (returns NUMBER)
CREATE OR REPLACE FUNCTION fn_total_sales_last_n_days(p_product_id IN NUMBER, p_days IN NUMBER) RETURN NUMBER IS
  v_total NUMBER;
BEGIN
  SELECT NVL(SUM(quantity_sold),0) INTO v_total
  FROM sales_history
  WHERE product_id = p_product_id
    AND sale_date >= SYSDATE - p_days;
  RETURN v_total;
END fn_total_sales_last_n_days;
/
--5) fn_customer_segment_label — lookup (returns VARCHAR2)
CREATE OR REPLACE FUNCTION fn_customer_segment_label(p_customer_id IN NUMBER) RETURN VARCHAR2 IS
  v_label VARCHAR2(100);
BEGIN
  SELECT segment_label INTO v_label FROM customer_segments WHERE customer_id = p_customer_id;
  RETURN v_label;
EXCEPTION
  WHEN NO_DATA_FOUND THEN
    RETURN 'UNCLASSIFIED';
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('fn_customer_segment_label', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 'ERROR';
END fn_customer_segment_label;
/

--D. Cursors & Bulk Processing examples
--1) Explicit cursor to process monthly sales and insert aggregated results into forecasts (example)
CREATE OR REPLACE PROCEDURE proc_aggregate_monthly_sales_to_forecast IS
  CURSOR c_prod IS SELECT DISTINCT product_id FROM sales_history;
  TYPE t_rec IS RECORD (product_id NUMBER);
  v_rec c_prod%ROWTYPE;
  v_sum NUMBER;
BEGIN
  OPEN c_prod;
  LOOP
    FETCH c_prod INTO v_rec;
    EXIT WHEN c_prod%NOTFOUND;
    SELECT NVL(SUM(quantity_sold),0) INTO v_sum
    FROM sales_history
    WHERE product_id = v_rec.product_id
      AND sale_date >= ADD_MONTHS(TRUNC(SYSDATE,'MM'), -1);
    -- Insert a simple forecast based on last month sales
    INSERT INTO forecasts(product_id, forecast_period_start, forecast_period_end, forecast_amount, model_type, confidence_score)
    VALUES (v_rec.product_id, TRUNC(SYSDATE,'MM'), LAST_DAY(SYSDATE), ROUND(v_sum * 1.1), 'monthly_agg', 0.75);
  END LOOP;
  CLOSE c_prod;
  COMMIT;
EXCEPTION WHEN OTHERS THEN
  INSERT INTO error_log(err_source, err_code, err_message, err_stack)
  VALUES('proc_aggregate_monthly_sales_to_forecast', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  ROLLBACK;
  RAISE;
END proc_aggregate_monthly_sales_to_forecast;
/
--2) Bulk Collect + FORALL to insert many inventory transactions (optimized)
CREATE OR REPLACE PROCEDURE proc_bulk_insert_inv_txn(p_count IN NUMBER) IS
  TYPE t_prod IS TABLE OF NUMBER;
  v_products t_prod := t_prod();
BEGIN
  -- build a collection of random product_ids
  FOR i IN 1..p_count LOOP
    v_products.EXTEND;
    v_products(v_products.COUNT) := TRUNC(DBMS_RANDOM.VALUE(1,51));
  END LOOP;

  FORALL i IN 1..v_products.COUNT
    INSERT INTO inventory_transactions(product_id, quantity, txn_type)
    VALUES (v_products(i), TRUNC(DBMS_RANDOM.VALUE(1,100)), 'RECEIPT');

  COMMIT;
EXCEPTION WHEN OTHERS THEN
  INSERT INTO error_log(err_source, err_code, err_message, err_stack)
  VALUES('proc_bulk_insert_inv_txn', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
  ROLLBACK;
  RAISE;
END proc_bulk_insert_inv_txn;
/

--E. Window functions — examples you can run to show advanced SQL usage
Run these as SELECT statements (not stored procedures). They are part of testing.
--1) ROW_NUMBER to get latest sale per product
SELECT product_id, sale_id, sale_date, quantity_sold
FROM (
  SELECT s.*, ROW_NUMBER() OVER (PARTITION BY product_id ORDER BY sale_date DESC) rn
  FROM sales_history s
)
WHERE rn = 1;
--2) RANK / DENSE_RANK — top customers by spend
SELECT customer_id, total_spent, RANK() OVER (ORDER BY total_spent DESC) rnk
FROM (
  SELECT c.customer_id, NVL(SUM(s.quantity_sold * s.unit_price_sold),0) total_spent
  FROM customers c LEFT JOIN sales_history s ON c.customer_id = s.customer_id
  GROUP BY c.customer_id
) t;
--3) LAG / LEAD — compare month-over-month sales per product
WITH monthly AS (
  SELECT product_id, TRUNC(sale_date,'MM') mon, SUM(quantity_sold) qty
  FROM sales_history
  GROUP BY product_id, TRUNC(sale_date,'MM')
)
SELECT product_id, mon, qty,
  LAG(qty) OVER (PARTITION BY product_id ORDER BY mon) prev_qty,
  LEAD(qty) OVER (PARTITION BY product_id ORDER BY mon) next_qty
FROM monthly
ORDER BY product_id, mon;
--4) Aggregate with OVER clause — running total per product
SELECT product_id, sale_date, quantity_sold,
  SUM(quantity_sold) OVER (PARTITION BY product_id ORDER BY sale_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) running_total
FROM sales_history
ORDER BY product_id, sale_date;

--F. Packages — design and implementation
We will create a package forecast_pkg to group forecasting-related functions and procedures.
--Package specification (public interface)
CREATE OR REPLACE PACKAGE forecast_pkg IS
  PROCEDURE refresh_forecast(p_product_id IN NUMBER);
  PROCEDURE refresh_all_forecasts;
  FUNCTION get_forecast(p_product_id IN NUMBER, p_periods IN NUMBER) RETURN NUMBER;
  FUNCTION forecast_confidence(p_product_id IN NUMBER) RETURN NUMBER;
END forecast_pkg;
/
--Package body (implementation)
CREATE OR REPLACE PACKAGE BODY forecast_pkg IS

  -- Simple refresh for one product (example: moving_avg of last 12 weeks)
  PROCEDURE refresh_forecast(p_product_id IN NUMBER) IS
    v_avg NUMBER;
  BEGIN
    SELECT NVL(ROUND(AVG(quantity_sold)),0) INTO v_avg
    FROM sales_history
    WHERE product_id = p_product_id
      AND sale_date >= SYSDATE - 84; -- last 12 weeks approx

    INSERT INTO forecasts(product_id, forecast_period_start, forecast_period_end, forecast_amount, model_type, confidence_score)
    VALUES (p_product_id, TRUNC(SYSDATE), TRUNC(LAST_DAY(SYSDATE)), v_avg, 'moving_avg_12w', 0.75);
    COMMIT;
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('forecast_pkg.refresh_forecast', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
  END refresh_forecast;

  -- Refresh for ALL products (cursor + commit every n)
  PROCEDURE refresh_all_forecasts IS
    CURSOR c_prod IS SELECT DISTINCT product_id FROM products;
    v_rec c_prod%ROWTYPE;
  BEGIN
    OPEN c_prod;
    LOOP
      FETCH c_prod INTO v_rec;
      EXIT WHEN c_prod%NOTFOUND;
      refresh_forecast(v_rec.product_id);
    END LOOP;
    CLOSE c_prod;
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('forecast_pkg.refresh_all_forecasts', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
  END refresh_all_forecasts;

  FUNCTION get_forecast(p_product_id IN NUMBER, p_periods IN NUMBER) RETURN NUMBER IS
    v_sum NUMBER;
  BEGIN
    SELECT NVL(SUM(forecast_amount),0) INTO v_sum
    FROM forecasts
    WHERE product_id = p_product_id
      AND forecast_period_start >= TRUNC(SYSDATE)
      AND ROWNUM <= p_periods;
    RETURN v_sum;
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('forecast_pkg.get_forecast', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    RETURN 0;
  END get_forecast;

  FUNCTION forecast_confidence(p_product_id IN NUMBER) RETURN NUMBER IS
    v_conf NUMBER;
  BEGIN
    SELECT NVL(AVG(confidence_score),0) INTO v_conf FROM forecasts WHERE product_id = p_product_id;
    RETURN v_conf;
  EXCEPTION WHEN OTHERS THEN
    RETURN 0;
  END forecast_confidence;

END forecast_pkg;
/

--G. Exception handling patterns & custom exceptions
--Define and use a custom exception in a procedure (example)
CREATE OR REPLACE PROCEDURE proc_safe_delete_product(p_product_id IN NUMBER) IS
  e_product_has_sales EXCEPTION;
  PRAGMA EXCEPTION_INIT(e_product_has_sales, -20002);
  v_cnt NUMBER;
BEGIN
  SELECT COUNT(*) INTO v_cnt FROM sales_history WHERE product_id = p_product_id;
  IF v_cnt > 0 THEN
    RAISE e_product_has_sales;
  END IF;

  DELETE FROM products WHERE product_id = p_product_id;
  COMMIT;
EXCEPTION
  WHEN e_product_has_sales THEN
    INSERT INTO error_log(err_source, err_code, err_message)
    VALUES('proc_safe_delete_product','-20002','Product has sales and cannot be deleted: '||p_product_id);
    ROLLBACK;
    -- propagate or handle silently
  WHEN OTHERS THEN
    INSERT INTO error_log(err_source, err_code, err_message, err_stack)
    VALUES('proc_safe_delete_product', SQLCODE, SUBSTR(SQLERRM,1,4000), DBMS_UTILITY.FORMAT_ERROR_BACKTRACE);
    ROLLBACK;
    RAISE;
END proc_safe_delete_product;
/

--H. Testing — how to run and what to capture
For each procedure/function/package above, run a simple test and capture output. I give sample calls below. Execute them and save results or screenshots.
--1) Test proc_insert_product
VAR out_id NUMBER;
EXEC proc_insert_product('Test Widget','Testing',19.99,100, :out_id);
PRINT :out_id;
--2) Test proc_record_sale
VAR v_sale NUMBER;
EXEC proc_record_sale(1, 1, SYSDATE, 2, fn_get_product_price(1), :v_sale);
PRINT :v_sale;
-- Then check stock:
SELECT product_id, product_name, current_stock FROM products WHERE product_id = 1;
--3) Test proc_generate_alerts_for_low_stock
EXEC proc_generate_alerts_for_low_stock;
SELECT COUNT(*) FROM alerts;
SELECT * FROM alerts WHERE acknowledged='N' AND ROWNUM <= 10;
--4) Test fn_calculate_reorder_qty
SELECT fn_calculate_reorder_qty(1) FROM dual;
--5) Test proc_bulk_insert_inv_txn
EXEC proc_bulk_insert_inv_txn(1000); -- insert 1000 inventory transactions quickly
SELECT COUNT(*) FROM inventory_transactions;
--6) Test package
EXEC forecast_pkg.refresh_forecast(1);
SELECT * FROM forecasts WHERE product_id = 1 ORDER BY computed_at DESC FETCH FIRST 5 ROWS ONLY;
--7) Test exception: try to delete a product with sales
EXEC proc_safe_delete_product(1);
-- then inspect error_log to see entry
SELECT * FROM error_log WHERE err_source='proc_safe_delete_product' ORDER BY err_timestamp DESC FETCH FIRST 5 ROWS ONLY;