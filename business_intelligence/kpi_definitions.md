# KPI Definitions — CustoVision

This document outlines the Key Performance Indicators (KPIs) used to monitor sales performance, forecasting accuracy, customer behavior, inventory health, and operational compliance within the CustoVision system.

---

## 1. Sales Performance KPIs

### **1.1 Total Sales Revenue**
| Item                | Description                                               |
|---------------------|-----------------------------------------------------------|
| **Measures**        | Total monetary value of all sales                         |
| **Formula / Logic** | `SUM(quantity_sold * unit_price_sold)`                    |
| **Source Tables**   | `sales_history`, `products`                               |
| **Frequency**       | Daily / Weekly / Monthly                                  |
| **Business Value**  | Indicates overall financial performance and profitability |

---

### **1.2 Top-Selling Products**
| Item                | Description                                                   |
|---------------------|---------------------------------------------------------------|
| **Measures**        | Products with the highest demand                              |
| **Formula / Logic** | `ORDER BY SUM(quantity_sold) DESC`                            |
| **Source Tables**   | `sales_history`                                               |
| **Frequency**       | Daily / Weekly                                                |
| **Business Value**  | Helps optimize stock levels, promotions, and product strategy |

---

### **1.3 Sales Growth Rate**
| Item                | Description                                  |
|---------------------|----------------------------------------------|
| **Measures**        | Change in sales between periods              |
| **Formula / Logic** | `(Current - Previous) / Previous * 100`      |
| **Source Tables**   | `sales_history`                              |
| **Frequency**       | Monthly                                      |
| **Business Value**  | Tracks business momentum and trend direction |

---

### **1.4 Average Order Value (AOV)**
| Item                | Description                                                        |
|---------------------|--------------------------------------------------------------------|
| **Measures**        | Average spend per order                                            |
| **Formula / Logic** | `Total Sales / Number of Orders`                                   |
| **Source Tables**   | `sales_history`                                                    |
| **Frequency**       | Daily / Monthly                                                    |
| **Business Value**  | Helps evaluate customer purchasing behavior and revenue efficiency |

---

## 2. Inventory & Operations KPIs

### **2.1 Current Stock Level**
| Item                  | Description                                                 |
|-----------------------|-------------------------------------------------------------|
| **Measures**          | Total available inventory                                   |
| **Formula / Logic**   | `SUM(receipts + adjustments - sales)` based on transactions |
| **Source Tables**     | `inventory_transactions`, `products`                        |
| **Frequency**         | Daily                                                       |
| **Business Value**    | Supports accurate replenishment planning                    |

---

### **2.2 Inventory Turnover**
| Item                | Description                                     |
|---------------------|-------------------------------------------------|
| **Measures**        | Speed at which inventory is sold                |
| **Formula / Logic** | `COALESCE(Sales Value / Avg Inventory, 0)`      |
| **Source Tables**   | `sales_history`, `inventory_transactions`       |
| **Frequency**       | Monthly                                         |
| **Business Value**  | Identifies slow-moving and fast-moving products |

---

### **2.3 Days of Inventory Remaining**
| Item                | Description                          |
|---------------------|--------------------------------------|
| **Measures**        | Expected remaining lifetime of stock |
| **Formula / Logic** | `Current Stock / Avg Daily Sales`    |
| **Source Tables**   | `products`, `sales_history`          |
| **Frequency**       | Weekly                               |
| **Business Value**  | Prevents overstocking or stockouts   |

---

### **2.4 Low-Stock Alerts Count**
| Item                | Description                                                  |
|---------------------|--------------------------------------------------------------|
| **Measures**        | Number of alerts generated due to low stock or forecast risk |
| **Formula / Logic** | `COUNT(alert_id)`                                            |
| **Source Tables**   | `alerts`                                                     |
| **Frequency**       | Daily                                                        |
| **Business Value**  | Ensures proactive replenishment and reduces shortages        |

---

## 3. Forecasting & Predictive KPIs

### **3.1 Forecast Accuracy**
| Item                | Description                                          |
|---------------------|------------------------------------------------------|
| **Measures**        | Accuracy of predicted demand                         |
| **Formula / Logic** | `(ABS(Forecast - Actual) / Actual) * 100`            |
| **Source Tables**   | `forecasts`, `sales_history`                         |
| **Frequency**       | Weekly / Monthly                                     |
| **Business Value**  | Improves prediction quality and operational planning |

---

### **3.2 Model Confidence Score**
| Item                | Description                                    |
|---------------------|------------------------------------------------|
| **Measures**        | Reliability of forecasting model               |
| **Formula / Logic** | `AVG(confidence_score)`                        |
| **Source Tables**   | `forecasts`                                    |
| **Frequency**       | Weekly / Monthly                               |
| **Business Value**  | Evaluates consistency of predictive algorithms |

---

## 4. Customer & Marketing KPIs

### **4.1 Customer Purchase Frequency**
| Item                | Description                                 |
|---------------------|---------------------------------------------|
| **Measures**        | Number of purchases per customer            |
| **Formula / Logic** | `COUNT(sale_id) GROUP BY customer_id`       |
| **Source Tables**   | `sales_history`                             |
| **Frequency**       | Monthly                                     |
| **Business Value**  | Helps identify loyal vs. inactive customers |

---

### **4.2 Customer Segment Distribution**
| Item                | Description                                       |
|---------------------|---------------------------------------------------|
| **Measures**        | Distribution of customers across segments         |
| **Formula / Logic** | `COUNT(customer_id) GROUP BY segment_label`       |
| **Source Tables**   | `customer_segments`                               |
| **Frequency**       | Monthly                                           |
| **Business Value**  | Enables targeted marketing and audience profiling |

---

### **4.3 Customer Retention Rate**
| Item                | Description                                     |
|---------------------|-------------------------------------------------|
| **Measures**        | Percentage of returning customers               |
| **Formula / Logic** | `(Returning Customers / Total Customers) * 100` |
| **Source Tables**   | `customers`, `sales_history`                    |
| **Frequency**       | Monthly                                         |
| **Business Value**  | Indicates business health and customer loyalty  |

---

## 5. Decision & Compliance KPIs

### **5.1 Decision Log Activity**
| Item                | Description                                   |
|---------------------|-----------------------------------------------|
| **Measures**        | Volume and type of system decisions performed |
| **Formula / Logic** | `COUNT(decision_id) GROUP BY decision_type`   |
| **Source Tables**   | `decision_log`                                |
| **Frequency**       | Weekly / Monthly                              |
| **Business Value**  | Ensures transparency and supports auditing    |

---

### **5.2 Alert Response Time**
| Item                | Description                                      |
|---------------------|--------------------------------------------------|
| **Measures**        | Time taken to resolve system alerts              |
| **Formula / Logic** | `Resolution Timestamp – Alert Timestamp`         |
| **Source Tables**   | `alerts`, `inventory_transactions`               |
| **Frequency**       | Weekly                                           |
| **Business Value**  | Tracks operational efficiency and responsiveness |

---

# Summary

These KPIs provide a complete monitoring framework covering:

- **Sales & Revenue**
- **Customer Behavior**
- **Inventory Health**
- **Forecasting Quality**
- **Compliance & Audit Monitoring**

Together, they enable CustoVision to function as a predictive, data-driven decision support system for business intelligence.

