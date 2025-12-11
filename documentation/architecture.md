# 🏛️ System Architecture – CustoVision MIS Analytics

This document explains the logical, physical, and analytical architecture of the CustoVision system.

---

# **1. High-Level Architecture Overview**

CustoVision is a modular MIS analytics platform that integrates:

- **Operational Data Layer (ODL)**
- **Analytical Data Layer (ADL)**
- **Business Intelligence Layer (BI)**
- **Monitoring & Alerts Engine**


---

# **2. Architecture Layers**

---

## **A. Operational Data Layer (ODL)**  
Core transactional entities:

- PRODUCTS  
- CUSTOMERS  
- SALES_HISTORY  
- INVENTORY_TRANSACTIONS

These support day-to-day MIS operations.

---

## **B. Analytical Data Layer (ADL)**  
Tables used for forecasting, segmentation, modeling:

- FORECASTS  
- CUSTOMER_SEGMENTS  
- ALERTS  
- DECISION_LOG  

They enable:

- AI/ML predictions  
- segmentation logic  
- audit tracking  
- demand planning  

---

## **C. Business Logic Layer (Triggers & Procedures)**  
Key logic components:

- **Holiday-based restriction trigger** – blocks product modifications on public holidays  
- **Weekday operations rule** – prevents risky updates outside approved hours  
- **Audit triggers** – record every change in ACTION_AUDIT  
- **Alert generation logic** – triggered when stock < forecast requirements  

---

## **D. Business Intelligence Layer (BI)**  

Used for dashboards in:

- Sales performance  
- Customer behavior  
- Stock levels  
- Forecast accuracy  
- Alert tracking  
- Operational audits  

Data comes from:

- SALES_HISTORY (fact)  
- ALERTS  
- FORECASTS  
- CUSTOMER_SEGMENTS  

KPIs are defined in `business_intelligence/kpi_definitions.md`.

---

## **E. Security & Governance**

- Audit logs (ACTION_AUDIT, DECISION_LOG)  
- Role-based update restrictions  
- Holiday + weekend business-rule enforcement  
- Data validation constraints  

---

# **3. Data Flow Diagram**

Raw transactions → SALES_HISTORY & INVENTORY_TRANSACTIONS

Products & customers → Dimension tables

Forecast model → FORECASTS

Alerts engine → ALERTS

Audits → DECISION_LOG, ACTION_AUDIT

BI Layer → KPIs, Dashboards, Reports


---

# **4. Technology Stack**

- **Oracle Database 19c**  
- **PL/SQL business logic**  
- **SQL Developer / SQL*Plus**  
- **Power BI / Tableau dashboards**  
- **GitHub for version control**

---

# **5. Scalability Considerations**

- Dimensions hundreds of thousands+
- Facts millions+
- Efficient indexing on product_id, customer_id, sale_date
- Partitioning for forecasts/sales recommended for production

---

