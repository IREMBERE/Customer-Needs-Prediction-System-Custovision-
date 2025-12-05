# CustoVision – Customer Needs Prediction System
📌 Project Overview

CustoVision is an Oracle PL/SQL–based intelligent prediction system designed to help businesses forecast customer needs before they occur. By analyzing historical sales patterns, customer behavior, and product trends, the system generates demand forecasts, customer segmentation, and automated stock alerts to support smarter and faster decision-making.

# 👤 Student Information

Name: Irembere Olivier

Student ID: 28392

# 📝 Problem Statement

Many businesses struggle with stockouts, over-purchasing, and unpredictable customer demand.
CustoVision addresses these challenges by using in-database analytics to forecast demand, segment customers, and generate automated alerts — enabling managers to make clear, data-driven decisions at the right time.

# 🎯 Key Objectives

Analyze historical sales data to detect buying patterns.

Forecast future product demand using PL/SQL algorithms.

Classify customers based on behavior and buying frequency.

Generate automated alerts for low stock or high forecasted demand.

Provide managers with actionable reports for inventory and marketing decisions.



# Phase II: Business Process Modeling

This section documents the business process design behind CustoVision – an MIS-driven system that predicts customer needs, analyzes sales behaviour, and generates automated stock alerts for managers.

# 1. Business Process Scope

Process Modeled:
Customer Demand Forecasting & Automated Stock Alert Workflow

Purpose:
To illustrate how sales data flows through the CustoVision MIS, how the system runs in-database analytics, and how managers receive actionable forecasting insights.

Objectives:

Detect buying patterns and forecast future product demand

Identify low-stock risks before sales are affected

Segment customers based on behavior and purchase frequency

Deliver automated alerts and forecast reports to decision makers

Expected Outcome:
Managers receive accurate, system-generated MIS reports that improve inventory planning, procurement, and marketing strategies.

# 2. Key Entities (Actors & Roles)
## Sales Staff

Records customer purchases

Updates daily sales transactions

## CustoVision MIS/Database (System Engine)

Stores all sales and customer data

Executes forecasting and segmentation algorithms

Runs scheduled batch jobs

Triggers automatic alerts and updates

## Inventory Department

Reviews stock level alerts

Approves replenishment or procurement actions

## Manager (Decision Maker)

Reviews MIS forecasts and segmentation reports

Decides on stocking, purchasing, and sales strategy

# 3. BPMN/SWIMLANE Workflow
---------------
# 4. MIS Relevance & Analytics Opportunities
✔ MIS Relevance

Automates data capture

Applies in-database analytics for forecasting

Provides real-time operational insights

Supports decision-making through reports & alerts

✔ Analytics Opportunities

Monthly demand forecasting

Customer segmentation for marketing

Low-stock detection

Trend analysis & seasonal pattern detection

Real-time performance dashboards



# 📌 Phase III: Logical Model Design

This phase focuses on designing a fully normalized logical data model (3NF minimum) for the CustoVision system to ensure data integrity, predictive analytics, and BI reporting capabilities.

## 1. Entity-Relationship Model (ERM)

### 🖇️Main Entities:

Products – items sold

Customers – customer info

Sales_History – transaction records

Forecasts – predicted demand data

Alerts – low-stock warnings

Customer_Segments – behavior-based classifications

Decision_Log – managerial decisions audit

Inventory_Transactions – stock updates

### 🖇️Cardinalities / Relationships:

Sales_History → Products: Many-to-One

Sales_History → Customers: Many-to-One

Forecasts → Products: Many-to-One

Alerts → Products / Forecasts: Many-to-One

Customer_Segments → Customers: One-to-One or One-to-Many

Decision_Log: Independent audit table

### 🖇️Constraints:

PK uniqueness for all entities

FK integrity enforced

NOT NULL for mandatory fields

### Data Dictionary 
______REMEMBER TABLE PICTURE ⚠️


# 3. Normalization Summary

1NF: All tables have atomic columns; no repeating groups

2NF: All non-key attributes fully depend on PKs (no partial dependencies)

3NF: No transitive dependencies; all attributes depend only on the primary key

Outcome: Fully normalized schema ensures minimal redundancy, data integrity, and supports predictive analytics.

# 4. BI & MIS Considerations

Fact Tables: Sales_History, Forecasts

Dimension Tables: Products, Customers, Customer_Segments

Slowly Changing Dimensions: Customer_Segments (Type 2 SCD recommended)

Aggregation Levels: Daily, weekly, monthly for sales and forecasts

Audit Trails: Alerts and Decision_Log record all actions with timestamps for accountability

# 5. Assumptions

One sale per product per customer per day

Forecasts computed per product per period (weekly or monthly)

Alerts triggered only when predicted demand exceeds current stock + safety margin

Decision_Log stores all managerial actions for auditing


