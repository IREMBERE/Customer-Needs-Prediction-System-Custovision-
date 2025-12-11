# 🧠 Design Decisions – CustoVision MIS Analytics

This document explains the reasoning behind each major design choice.

---

# **1. Star Schema Approach**

i designed a **Star Schema** (dimensional model) because:

- Supports analytics & BI efficiently  
- Simplifies joins  
- Makes KPIs & dashboards faster  
- Easy to scale horizontally  

**Facts:** SALES_HISTORY, FORECASTS  
**Dimensions:** PRODUCTS, CUSTOMERS, CUSTOMER_SEGMENTS

---

# **2. Separation of Operational & Analytical Tables**

Why?

- Avoid mixing OLTP (transactions) with OLAP (analytics)
- Forecasts and segments are computational results — not raw data
- Alerts rely on analytical logic, so they should not belong to operational layer

---

# **3. Use of Audit Tables**

Two layers of auditing were added:

## **A. ACTION_AUDIT**
Tracks all inserts/updates/deletes  
Ensures compliance, transparency, and traceability.

## **B. DECISION_LOG**
Captures managerial/system decisions  
Used for BI reporting and debugging.

---

# **4. Inclusion of PUBLIC_HOLIDAYS Table**

Reason:

- Some processes should be blocked on official holidays  
- Supports “safe-update” policy  
- Mimics real corporate governance

---

# **5. Trigger-Based Business Rules**

Triggers were used to enforce:

- No updates on public holidays  
- No product modifications during restricted hours  
- Automatic audit trail creation  

Triggers ensure consistency even if applications change.

---

# **6. Forecast & Alerts Design**

Forecasts stored in their own table to allow:

- Multiple model runs  
- Model comparison  
- Confidence scores  
- Historical forecast archives  

Alerts reference forecasts so the system can show:

- Why an alert happened  
- Which model triggered it  

---

# **7. Customer Segmentation as a Dimension**

Segmentation is stored separately because:

- Segments change over time  
- Used for targeted marketing  
- BI dashboards require historical segmentation snapshots  

---

# **8. Numeric & Date Choices**

- NUMBER type for IDs for compatibility  
- DATE for business dates  
- TIMESTAMP for precise event tracking  
- CHECK constraints ensure data quality (price > 0, qty > 0)

---

# **9. Naming Conventions**

- ALL CAPS for table names (Oracle best practice)  
- snake_case for attributes  
- *_id suffix for primary keys  
- *_date and *_ts for time-related fields  

Ensures readability and uniformity.

---

# **10. Why We Did NOT Normalize Everything**

We avoided over-normalization because:

- This is an analytics system (not pure transactional)  
- Performance is more important than 100% normalization  
- Reducing join complexity improves dashboard performance  

---

# **11. Why We Centralized Business Logic in DB**

Complex logic (alerts, auditing, restrictions) lives in the DB because:

- Ensures consistent behavior across applications  
- Reduces risk of bypassing logic  
- Easier to maintain & version-control  
- Faster performance for large datasets  

---

# **12. Extensibility**

The structure allows easy expansion:

- Add new dimensions  
- Add new forecast models  
- Insert new KPI definitions  
- Add dashboards without changing table structure  

---

# **Conclusion**

These decisions ensure:

- Data integrity  
- High performance  
- Scalability  
- Auditability  
- Business alignment  
- Easy BI reporting  

CustoVision is ready for deeper analytics, ML integration, and enterprise reporting.

