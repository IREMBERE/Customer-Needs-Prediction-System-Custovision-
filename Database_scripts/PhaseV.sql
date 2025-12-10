--1 - Sequences (for PK auto-increment)
CREATE SEQUENCE seq_products START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_customers START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_sales START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_forecasts START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_alerts START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_segments START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_decision START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;
CREATE SEQUENCE seq_inv_txn START WITH 1 INCREMENT BY 1 NOCACHE NOCYCLE;

--2 - Table creation (DDL) — matches your ERM & data types
-- PRODUCTS (dimension)
CREATE TABLE products (
  product_id       NUMBER PRIMARY KEY,
  product_name     VARCHAR2(150) NOT NULL,
  category         VARCHAR2(100),
  unit_price       NUMBER(12,2) CONSTRAINT chk_unit_price CHECK (unit_price >= 0),
  current_stock    NUMBER DEFAULT 0 CONSTRAINT chk_stock CHECK (current_stock >= 0)
);

-- CUSTOMERS (dimension)
CREATE TABLE customers (
  customer_id      NUMBER PRIMARY KEY,
  customer_name    VARCHAR2(200) NOT NULL,
  email            VARCHAR2(150) UNIQUE,
  city             VARCHAR2(100),
  country          VARCHAR2(100),
  demographics     VARCHAR2(400)
);

-- SALES_HISTORY (fact)
CREATE TABLE sales_history (
  sale_id          NUMBER PRIMARY KEY,
  product_id       NUMBER NOT NULL,
  customer_id      NUMBER,
  sale_date        DATE DEFAULT SYSDATE NOT NULL,
  quantity_sold    NUMBER NOT NULL CONSTRAINT chk_qty CHECK (quantity_sold > 0),
  unit_price_sold  NUMBER(12,2) NOT NULL,
  CONSTRAINT fk_sales_products FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_sales_customers FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- FORECASTS (fact)
CREATE TABLE forecasts (
  forecast_id           NUMBER PRIMARY KEY,
  product_id            NUMBER NOT NULL,
  forecast_period_start DATE NOT NULL,
  forecast_period_end   DATE NOT NULL,
  forecast_amount       NUMBER NOT NULL,
  model_type            VARCHAR2(50),
  confidence_score      NUMBER(3,2) DEFAULT 0.00 CHECK (confidence_score BETWEEN 0 AND 1),
  computed_at           TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_forecast_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

-- ALERTS
CREATE TABLE alerts (
  alert_id       NUMBER PRIMARY KEY,
  product_id     NUMBER NOT NULL,
  forecast_id    NUMBER,
  alert_date     TIMESTAMP DEFAULT SYSTIMESTAMP,
  recommended_qty NUMBER,
  alert_reason   VARCHAR2(400),
  acknowledged   CHAR(1) DEFAULT 'N' CHECK (acknowledged IN ('Y','N')),
  CONSTRAINT fk_alert_product FOREIGN KEY (product_id) REFERENCES products(product_id),
  CONSTRAINT fk_alert_forecast FOREIGN KEY (forecast_id) REFERENCES forecasts(forecast_id)
);

-- CUSTOMER_SEGMENTS (dimension)
CREATE TABLE customer_segments (
  segment_id     NUMBER PRIMARY KEY,
  customer_id    NUMBER NOT NULL,
  segment_label  VARCHAR2(100),
  segment_score  NUMBER(5,2),
  computed_at    TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_seg_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

-- DECISION_LOG (audit)
CREATE TABLE decision_log (
  decision_id      NUMBER PRIMARY KEY,
  actor            VARCHAR2(100),
  decision_type    VARCHAR2(100),
  decision_ts      TIMESTAMP DEFAULT SYSTIMESTAMP,
  data_payload     CLOB
);

-- INVENTORY_TRANSACTIONS
CREATE TABLE inventory_transactions (
  inv_txn_id     NUMBER PRIMARY KEY,
  product_id     NUMBER NOT NULL,
  quantity       NUMBER NOT NULL,
  txn_type       VARCHAR2(20) CHECK (txn_type IN ('ADJUSTMENT','RECEIPT','SALE','RETURN')),
  txn_date       TIMESTAMP DEFAULT SYSTIMESTAMP,
  CONSTRAINT fk_inv_product FOREIGN KEY (product_id) REFERENCES products(product_id)
);

--3 - Triggers to auto-populate PKs (convenience)
CREATE OR REPLACE TRIGGER trg_products_pk BEFORE INSERT ON products FOR EACH ROW
BEGIN :NEW.product_id := seq_products.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_customers_pk BEFORE INSERT ON customers FOR EACH ROW
BEGIN :NEW.customer_id := seq_customers.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_sales_pk BEFORE INSERT ON sales_history FOR EACH ROW
BEGIN :NEW.sale_id := seq_sales.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_forecasts_pk BEFORE INSERT ON forecasts FOR EACH ROW
BEGIN :NEW.forecast_id := seq_forecasts.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_alerts_pk BEFORE INSERT ON alerts FOR EACH ROW
BEGIN :NEW.alert_id := seq_alerts.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_segments_pk BEFORE INSERT ON customer_segments FOR EACH ROW
BEGIN :NEW.segment_id := seq_segments.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_decision_pk BEFORE INSERT ON decision_log FOR EACH ROW
BEGIN :NEW.decision_id := seq_decision.NEXTVAL; END; /

CREATE OR REPLACE TRIGGER trg_inv_txn_pk BEFORE INSERT ON inventory_transactions FOR EACH ROW
BEGIN :NEW.inv_txn_id := seq_inv_txn.NEXTVAL; END; /

--4 - Indexes (for joins/queries)
CREATE INDEX idx_sales_product ON sales_history(product_id);
CREATE INDEX idx_sales_customer ON sales_history(customer_id);
CREATE INDEX idx_forecast_product ON forecasts(product_id);
CREATE INDEX idx_alert_product ON alerts(product_id);
CREATE INDEX idx_inv_product ON inventory_transactions(product_id);

-- Optional composite index for analytics on date
CREATE INDEX idx_sales_prod_date ON sales_history(product_id, sale_date);

--5 - Data generation (PL/SQL) — realistic rows and edge cases
Run these after the tables & triggers exist. They generate:
Products = 50, Customers = 300, Sales = 2000, Forecasts = 150 (50x3), Segments = 300, Inv Txn = 200, Alerts=50, Decision_Log=20.
--5.1 Products (50)
BEGIN
  FOR i IN 1..50 LOOP
    INSERT INTO products(product_name, category, unit_price, current_stock)
    VALUES (
      'Product ' || LPAD(i,3,'0'),
      CASE WHEN MOD(i,5)=0 THEN 'Electronics'
           WHEN MOD(i,5)=1 THEN 'Grocery'
           WHEN MOD(i,5)=2 THEN 'Apparel'
           WHEN MOD(i,5)=3 THEN 'Home'
           ELSE 'Sports' END,
      ROUND(DBMS_RANDOM.VALUE(5,500),2),
      TRUNC(DBMS_RANDOM.VALUE(0,500))
    );
  END LOOP;
  COMMIT;
END;
/
--5.2 Customers (300) — includes some NULL emails (edge cases)
BEGIN
  FOR i IN 1..300 LOOP
    INSERT INTO customers(customer_name, email, city, country, demographics)
    VALUES (
      'Customer ' || LPAD(i,4,'0'),
      CASE WHEN MOD(i,10)=0 THEN NULL ELSE 'cust' || i || '@example.com' END,
      CASE WHEN MOD(i,6)=0 THEN 'Kigali'
           WHEN MOD(i,6)=1 THEN 'Nairobi'
           WHEN MOD(i,6)=2 THEN 'Kampala'
           WHEN MOD(i,6)=3 THEN 'Lagos'
           WHEN MOD(i,6)=4 THEN 'Addis Ababa'
           ELSE 'Accra' END,
      CASE WHEN MOD(i,3)=0 THEN 'Rwanda' WHEN MOD(i,3)=1 THEN 'Kenya' ELSE 'Uganda' END,
      'age:' || TO_CHAR(18 + MOD(i,50)) || ';gender:' || CASE WHEN MOD(i,2)=0 THEN 'M' ELSE 'F' END
    );
  END LOOP;
  COMMIT;
END;
/
--5.3 Sales History (2000) — some customer_id NULL to represent walk-ins
DECLARE
  v_price NUMBER;
  v_prod  NUMBER;
  v_cust  NUMBER;
BEGIN
  FOR i IN 1..2000 LOOP
    v_prod := TRUNC(DBMS_RANDOM.VALUE(1,51));
    SELECT unit_price INTO v_price FROM products WHERE product_id = v_prod;
    v_cust := CASE WHEN MOD(i,50)=0 THEN NULL ELSE TRUNC(DBMS_RANDOM.VALUE(1,301)) END;
    INSERT INTO sales_history(product_id, customer_id, sale_date, quantity_sold, unit_price_sold)
    VALUES (
      v_prod,
      v_cust,
      TRUNC(SYSDATE - DBMS_RANDOM.VALUE(1,365)),
      TRUNC(DBMS_RANDOM.VALUE(1,10)),
      ROUND(v_price * (1 + DBMS_RANDOM.VALUE(-0.1, 0.2)), 2)
    );
  END LOOP;
  COMMIT;
END;
/
--5.4 Forecasts (50 products × 3 months = 150)
BEGIN
  FOR p IN 1..50 LOOP
    FOR m IN 0..2 LOOP
      INSERT INTO forecasts(product_id, forecast_period_start, forecast_period_end, forecast_amount, model_type, confidence_score)
      VALUES (
        p,
        TRUNC(ADD_MONTHS(TRUNC(SYSDATE,'MM'), m)),
        TRUNC(LAST_DAY(ADD_MONTHS(TRUNC(SYSDATE,'MM'), m))),
        ROUND(DBMS_RANDOM.VALUE(5,300),0),
        CASE WHEN MOD(p,3)=0 THEN 'moving_avg' WHEN MOD(p,3)=1 THEN 'weighted' ELSE 'linear_trend' END,
        ROUND(DBMS_RANDOM.VALUE(0.45,0.98),2)
      );
    END LOOP;
  END LOOP;
  COMMIT;
END;
/
--5.5 Customer Segments (300)
BEGIN
  FOR c IN 1..300 LOOP
    INSERT INTO customer_segments(customer_id, segment_label, segment_score)
    VALUES (
      c,
      CASE WHEN MOD(c,4)=0 THEN 'Frequent' WHEN MOD(c,4)=1 THEN 'Occasional' WHEN MOD(c,4)=2 THEN 'Seasonal' ELSE 'Loyal' END,
      ROUND(DBMS_RANDOM.VALUE(0,100),2)
    );
  END LOOP;
  COMMIT;
END;
/
--5.6 Inventory Transactions (200)
BEGIN
  FOR i IN 1..200 LOOP
    INSERT INTO inventory_transactions(product_id, quantity, txn_type, txn_date)
    VALUES (
      TRUNC(DBMS_RANDOM.VALUE(1,51)),
      TRUNC(DBMS_RANDOM.VALUE(1,500)),
      CASE WHEN MOD(i,3)=0 THEN 'RECEIPT' WHEN MOD(i,3)=1 THEN 'ADJUSTMENT' ELSE 'RECEIPT' END,
      SYSTIMESTAMP - NUMTODSINTERVAL(TRUNC(DBMS_RANDOM.VALUE(1,365)),'DAY')
    );
  END LOOP;
  COMMIT;
END;
/
--5.7 Alerts & Decision_Log (seed)
BEGIN
  FOR i IN 1..50 LOOP
    INSERT INTO alerts(product_id, forecast_id, recommended_qty, alert_reason)
    VALUES (
      TRUNC(DBMS_RANDOM.VALUE(1,51)),
      NULL,
      TRUNC(DBMS_RANDOM.VALUE(10,100)),
      'Projected demand exceeds current stock'
    );
  END LOOP;
  COMMIT;
END;
/

BEGIN
  FOR i IN 1..20 LOOP
    INSERT INTO decision_log(actor, decision_type, data_payload)
    VALUES (
      CASE WHEN MOD(i,2)=0 THEN 'Manager A' ELSE 'Manager B' END,
      'REORDER',
      'payload={product:'||TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(1,51)))||',qty:'||TO_CHAR(TRUNC(DBMS_RANDOM.VALUE(10,100)))||'}'
    );
  END LOOP;
  COMMIT;
END;
/
--6 - Validation & Integrity checks (queries to run & save results)
Run these and save outputs (CSV / screenshot) as proof.
--6.1 Row counts
SELECT 'products' name, COUNT(*) cnt FROM products
UNION ALL SELECT 'customers', COUNT(*) FROM customers
UNION ALL SELECT 'sales_history', COUNT(*) FROM sales_history
UNION ALL SELECT 'forecasts', COUNT(*) FROM forecasts
UNION ALL SELECT 'alerts', COUNT(*) FROM alerts
UNION ALL SELECT 'segments', COUNT(*) FROM customer_segments
UNION ALL SELECT 'inv_txn', COUNT(*) FROM inventory_transactions;
--6.2 Orphan FK checks (should return zero rows)
-- Sales with invalid product (should be none)
SELECT s.sale_id FROM sales_history s LEFT JOIN products p ON s.product_id = p.product_id WHERE p.product_id IS NULL;

-- Sales with invalid customer (should be none except where customer_id is NULL intentionally)
SELECT s.sale_id FROM sales_history s LEFT JOIN customers c ON s.customer_id = c.customer_id WHERE s.customer_id IS NOT NULL AND c.customer_id IS NULL;
--6.3 NOT NULL / CHECK enforcement example (attempt insert that fails)
-- Expect failure: quantity_sold must be > 0
INSERT INTO sales_history(product_id, customer_id, sale_date, quantity_sold, unit_price_sold)
VALUES (1, 1, SYSDATE, 0, 10);
-- Rollback after observing error
ROLLBACK;
--6.4 Aggregations & joins (sample useful queries)
-- Top-selling products (quantity)
SELECT p.product_id, p.product_name, NVL(SUM(s.quantity_sold),0) total_qty
FROM products p LEFT JOIN sales_history s ON p.product_id = s.product_id
GROUP BY p.product_id, p.product_name
ORDER BY total_qty DESC;

-- Top customers by spend
SELECT c.customer_id, c.customer_name, NVL(SUM(s.quantity_sold * s.unit_price_sold),0) total_spent
FROM customers c LEFT JOIN sales_history s ON c.customer_id = s.customer_id
GROUP BY c.customer_id, c.customer_name
ORDER BY total_spent DESC FETCH FIRST 20 ROWS ONLY;

-- Products that may need reorder (forecast > current_stock)
SELECT p.product_id, p.product_name, MAX(f.forecast_amount) forecast_amt, p.current_stock
FROM forecasts f JOIN products p ON f.product_id = p.product_id
GROUP BY p.product_id, p.product_name, p.current_stock
HAVING MAX(f.forecast_amount) > p.current_stock;