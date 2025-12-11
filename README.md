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



# 📌 Phase II: Business Process Modeling

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
---
# 3. BPMN/SWIMLANE Workflow

![BPMN Diagram](screenshoots/database_objects/PHASE%20II%20CustoVision_BPMN_Diagram.png)
---
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
![Phase 3 Custovision Data Dictionary](screenshoots/database_objects/Phase%203Custovision%20Data%20Dictionary.png)


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


# 📌Phase IV: Database Creation

Phase IV focuses on creating and configuring the Oracle database to provide a robust foundation for the physical tables and subsequent data insertion in Phase V.

## Objectives

Set up an Oracle pluggable database (PDB) for CustoVision.

Configure tablespaces for data, indexes, and temporary operations.

Set memory parameters (SGA and PGA) for optimal performance.

Enable archive logging for recovery and auditing.

Configure autoextend parameters for tablespaces.

Document database creation and configuration for reproducibility.

## Database Configuration Highlights

### Tablespaces:

CUSTOVISION_DATA → stores main tables.

CUSTOVISION_IDX → stores indexes.

TEMP → temporary operations and sorting.

### Memory Parameters:

SGA (System Global Area) and PGA (Program Global Area) tuned for PL/SQL analytics.

### Logging & Recovery:

Archive logging enabled to support point-in-time recovery.

### Autoextend:

Tablespaces configured to autoextend as data grows.

### Users & Permissions:

CUSTOVISION_ADMIN user created with required privileges.


# 📌 Phase V: Table Implementation & Data Insertion

Phase IV focuses on building the physical database structure, populating it with realistic data, and verifying data integrity to support analytics and business intelligence.

## Objectives

Convert all entities from the logical model into physical tables in Oracle.

Define primary keys (PKs), foreign keys (FKs), and indexes.

Enforce data constraints: NOT NULL, UNIQUE, CHECK, DEFAULT.

Insert 100–500+ realistic rows per main table reflecting real business scenarios.

Test data integrity and validate business rules.

Run queries to verify correct table relationships, aggregation, and reporting readiness.

## Table Implementation Highlights

Products: Tracks items sold, categories, and current stock.

Customers: Includes demographics, city, country, and email.

Sales_History: Records transactions with product, customer, quantity, and unit price.

Forecasts: Contains predicted demand with confidence scores and model types.

Alerts: Low-stock notifications linked to products and forecasts.

Customer_Segments: Classification based on purchase frequency and behavior.

Decision_Log: Stores managerial decisions for audit.

Inventory_Transactions: Tracks stock changes with transaction type.

Supporting Tables: Public holidays, action audit for MIS compliance.

## Constraints & Indexes:

PKs ensure uniqueness.

FKs enforce relational integrity.

CHECK constraints validate business rules (e.g., quantity > 0, acknowledged status ‘Y/N’).

Indexes created on frequent join columns to improve query performance.

## Data Insertion

Realistic rows generated for each table using PL/SQL loops and DBMS_RANDOM.

Edge cases handled: NULL emails, walk-in customers, zero stock products.

Data distributions simulate actual business patterns (demographics, seasonal sales, product categories).

## Data Verification & Testing
 ### Basic retrieval (SELECT *)
 ### Joins (multi-table queries)
 ### Aggregations (GROUP BY)
 ### Subqueries



# 📌Phase VI: Database Interaction & Transactions

Phase VI focuses on developing the PL/SQL layer of CustoVision to handle all transactional and analytical operations. This includes procedures, functions, cursors, window functions, and packages, enabling automated customer demand forecasting, segmentation, and stock alerts.

## Objectives

Implement PL/SQL procedures for INSERT, UPDATE, DELETE operations with exception handling.

Create functions for calculations, validation, and lookups.

Use explicit cursors and bulk operations for efficient multi-row processing.

Apply window functions (ROW_NUMBER, RANK, LAG, LEAD, aggregates with OVER clause) for analytics.

Organize related operations into packages for modularity and maintainability.

Handle exceptions with predefined and custom error logging.

Verify correctness and performance with thorough testing.

## Key Components
### 1. Procedures

Minimum of 3–5 parameterized procedures.

Include IN, OUT, and IN OUT parameters.

Support DML operations on Sales_History, Forecasts, Alerts, Customer_Segments.

Exception handling ensures transaction rollback and logging.

### 2. Functions

Minimum of 3–5 functions.

Types:

Calculation functions (e.g., compute predicted demand)

Validation functions (e.g., check stock levels)

Lookup functions (e.g., get customer segment)

Proper return types with error handling.

### 3. Cursors

Explicit cursors for multi-row queries.

OPEN → FETCH → CLOSE pattern implemented.

Bulk processing for efficiency.

### 4. Window Functions

ROW_NUMBER(), RANK(), DENSE_RANK() to rank customers and products.

LAG(), LEAD() to compare periods and compute trends.

Aggregate functions with OVER for moving totals and averages.

### 5. Packages

Packages group related procedures/functions.

Include package specification (public interface) and package body (implementation).

Enhances modularity and maintainability.

### 6. Exception Handling

Predefined Oracle exceptions handled.

Custom exceptions defined for business rules (e.g., low stock, invalid input).

Error logging and recovery mechanisms implemented.

### 7.Testing

All procedures/functions tested for correctness.

Edge cases validated (nulls, invalid data, extreme values).

Performance tested for bulk operations.

Test results documented in GitHub submission.


# 📌Phase VII: Advanced Programming & Auditing

Phase VII enhances CustoVision by implementing business rules, triggers, and auditing mechanisms. The system ensures that employees comply with operational restrictions while maintaining full audit trails of all database operations. This phase strengthens data governance, integrity, and accountability in the MIS environment.

## Objectives

Enforce critical business restrictions: no DML (INSERT, UPDATE, DELETE) on weekdays and public holidays.

Implement audit logging to capture all employee actions, including denied attempts.

Develop PL/SQL triggers (simple and compound) to enforce rules.

Provide clear error messages for non-compliant operations.

Maintain comprehensive user and timestamp tracking for accountability.

## Key Components
### 1. Holiday Management

Table public_holidays stores dates for the upcoming month.

Supports dynamic holiday checking in triggers and functions.

CREATE TABLE public_holidays (
    
    holiday_date DATE PRIMARY KEY,
    description  VARCHAR2(200)
);

### 2. Audit Log Table

CREATE TABLE action_audit (
   
    audit_id        NUMBER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    username        VARCHAR2(100),
    action_type     VARCHAR2(20),   -- INSERT, UPDATE, DELETE
    table_name      VARCHAR2(50),
    action_time     TIMESTAMP,
    allowed         VARCHAR2(10),   -- 'YES' or 'NO'
    reason          VARCHAR2(200)   -- If blocked, explain why
);


### 3. Audit Logging Function

PL/SQL function logs all actions into audit_log.

Called from triggers to ensure every attempt is recorded.

### 4. Restriction Check Function

Checks if the current date is:

A weekday (Monday–Friday)

A public holiday

Returns BOOLEAN for trigger validation.

### 5. Simple Triggers

Row-level triggers enforce:

Block DML on weekdays

Allow DML on weekends

Block DML on holidays

Call restriction check and logging functions.

### 6. Compound Trigger

Handles multi-row operations efficiently.

Ensures logging and enforcement at statement and row levels.

## Testing Requirements

Attempted INSERT on weekday → DENIED

Attempted INSERT on weekend → ALLOWED

Attempted INSERT on public holiday → DENIED

Audit log captures all attempts with details

Error messages are clear and informative

User info is accurately recorded for accountability
