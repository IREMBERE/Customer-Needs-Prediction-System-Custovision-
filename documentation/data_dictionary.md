# 📘 Data Dictionary – CustoVision MIS Analytics System

This document describes all entities, attributes, data types, constraints, and business meaning within the CustoVision database.  
It supports understanding, maintenance, analytics, and BI reporting.

---

## **1. PRODUCTS (Dimension Table)**

| Column Name    | Data Type        | Description                | Constraints           |
|----------------|------------------|----------------------------|-----------------------|
| product_id     | NUMBER (PK)      | Unique ID for each product | Primary Key           |
| product_name   | VARCHAR2(150)    | Name of product            | NOT NULL              |
| category       | VARCHAR2(100)    | Product group/category     | Optional              |
| unit_price     | NUMBER(12,2)     | Standard unit price        | CHECK (≥0)            |
| current_stock  | NUMBER           | Current stock level        | DEFAULT 0, CHECK (≥0) |

**Business Role:**  
Stores master data for products. Used in sales, forecasts, inventory, and alerts.

---

## **2. CUSTOMERS (Dimension Table)**

| Column Name    | Data Type         | Description               | Constraints |
|----------------|-------------------|---------------------------|-------------|
| customer_id    | NUMBER (PK)       | Unique ID for a customer  | Primary Key |
| customer_name  | VARCHAR2(200)     | Full customer name        | NOT NULL    |
| email          | VARCHAR2(150)     | Email address             | UNIQUE      |
| city           | VARCHAR2(100)     | Customer location         | Optional    |
| country        | VARCHAR2(100)     | Customer country          | Optional    |
| demographics   | VARCHAR2(400)     | Age, gender, income, etc. | Optional    |

**Business Role:**  
Supports sales analysis, segmentation, and customer behavior insights.

---

## **3. SALES_HISTORY (Fact Table)**

| Column Name     | Data Type        | Description             | Constraints     |
|-----------------|------------------|-------------------------|-----------------|
| sale_id         | NUMBER (PK)      | Unique sale transaction | Primary Key     |
| product_id      | NUMBER           | Product sold            | FK → PRODUCTS   |
| customer_id     | NUMBER           | Customer purchasing     | FK → CUSTOMERS  |
| sale_date       | DATE             | Date of sale            | DEFAULT SYSDATE |
| quantity_sold   | NUMBER           | Units sold              | CHECK (>0)      |
| unit_price_sold | NUMBER(12,2)     | Price at time of sale   | NOT NULL        |

**Business Role:**  
Central fact table for BI dashboards: revenue, performance, trends.

---

## **4. FORECASTS (Fact Table)**

| Column Name            | Data Type        | Description            | Constraints          |
|------------------------|------------------|------------------------|----------------------|
| forecast_id            | NUMBER (PK)      | Forecast entry ID      | PK                   |
| product_id             | NUMBER           | Product for forecast   | FK → PRODUCTS        |
| forecast_period_start  | DATE             | Start period           | NOT NULL             |
| forecast_period_end    | DATE             | End period             | NOT NULL             |
| forecast_amount        | NUMBER           | Predicted demand       | NOT NULL             |
| model_type             | VARCHAR2(50)     | AI/ML model identifier | Optional             |
| confidence_score       | NUMBER(3,2)      | Model confidence       | RANGE 0–1            |
| computed_at            | TIMESTAMP        | Model run timestamp    | DEFAULT SYSTIMESTAMP |

**Business Role:**  
Supports demand forecasting, replenishment, and optimization.

---

## **5. ALERTS**

| Column Name     | Data Type     | Description                               | Constraints          |
|-----------------|---------------|-------------------------------------------|----------------------|
| alert_id        | NUMBER (PK)   | Unique alert                              | PK                   |
| product_id      | NUMBER        | Related product                           | FK → PRODUCTS        |
| forecast_id     | NUMBER        | Related forecast                          | FK → FORECASTS       |
| alert_date      | TIMESTAMP     | When alert was triggered                  | DEFAULT SYSTIMESTAMP |
| recommended_qty | NUMBER        | Suggested reorder qty                     | Optional             |
| alert_reason    | VARCHAR2(400) | Shortage, overstock, forecast error, etc. | -                    |
| acknowledged    | CHAR(1)       | Whether alert is handled                  | CHECK 'Y','N'        |

**Business Role:**  
Triggers and dashboard notifications for stock issues.

---

## **6. CUSTOMER_SEGMENTS**

| Column Name    | Data Type        | Description                 | Constraints          |
|----------------|------------------|-----------------------------|----------------------|
| segment_id     | NUMBER (PK)      | Unique segment entry        | PK                   |
| customer_id    | NUMBER           | Customer                    | FK → CUSTOMERS       |
| segment_label  | VARCHAR2(100)    | Category (e.g., High Value) | Optional             |
| segment_score  | NUMBER(5,2)      | Customer ranking score      | Optional             |
| computed_at    | TIMESTAMP        | Segmentation timestamp      | DEFAULT SYSTIMESTAMP |

**Business Role:**  
Used in personalized marketing and churn analysis.

---

## **7. DECISION_LOG**

| Column Name     | Data Type     | Description                   |
|-----------------|---------------|-------------------------------|
| decision_id     | NUMBER PK     | Log entry                     |
| actor           | VARCHAR2(100) | User/system initiating action |
| decision_type   | VARCHAR2(100) | Type: APPROVE, REJECT, UPDATE |
| decision_ts     | TIMESTAMP     | Timestamp                     |
| data_payload    | CLOB          | JSON/XML of old/new values    |

**Business Role:**  
Transparency, auditing, BI analysis of decisions.

---

## **8. INVENTORY_TRANSACTIONS**

| Column Name | Data Type    | Description                    | Constraints     |
|-------------|--------------|--------------------------------|-----------------|
| inv_txn_id  | NUMBER PK    | Transaction                    | PK              |
| product_id  | NUMBER       | Product                        | FK → PRODUCTS   |
| quantity    | NUMBER       | Adjustment value               | NOT NULL        |
| txn_type    | VARCHAR2(20) | ADJUSTMENT/RECEIPT/SALE/RETURN | CHECK           |
| txn_date    | TIMESTAMP    | Time of update                 | DEFAULT SYSDATE |

**Business Role:**  
Tracks stock movement, used in KPIs like turnover and stock days.

---

## **9. ACTION_AUDIT (Blocker/Validator)**

| Column Name  | Data Type      | Description            |
|--------------|----------------|------------------------|
| audit_id     | NUMBER PK      | Audit entry            |
| username     | VARCHAR2(100)  | User performing action |
| action_type  | VARCHAR2(20)   | INSERT/UPDATE/DELETE   |
| table_name   | VARCHAR2(50)   | Table affected         |
| action_time  | TIMESTAMP      | Timestamp              |
| allowed      | VARCHAR2(10)   | YES/NO                 |
| reason       | VARCHAR2(200)  | If blocked, why        |

---

## **10. PUBLIC_HOLIDAYS**

| Column Name  | Data Type     | Description           |
|--------------|---------------|-----------------------|
| holiday_date | DATE PK       | Day of public holiday |
| description  | VARCHAR2(200) | Name of holiday       |

---

