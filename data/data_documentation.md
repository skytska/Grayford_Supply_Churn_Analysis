# Data Documentation

---

## 1. Data Source

**Original file:** `Online Retail.xlsx`  
**Source:** [archive.ics.uci.edu]('https://archive.ics.uci.edu/dataset/352/online+retail') 

This is a transactional dataset containing all purchases between **01/12/2010 and 09/12/2011** for a UK-based non-store online retail company.  

The company primarily sells **unique, all-occasion gifts**, and a significant portion of its customers are **wholesalers**.

### Dataset Characteristics
- **Type:** Multivariate, Sequential, Time-Series  
- **Domain:** Business  
- **Use Cases:** Classification, Clustering  

### Data Overview
- **Number of records:** 541,909  
- **Number of features:** 6  

### Raw Data Fields
- `InvoiceNo` — unique transaction identifier  
- `StockCode` — product/item code  
- `Description` — product name  
- `Quantity` — number of items purchased  
- `InvoiceDate` — date and time of transaction  
- `UnitPrice` — price per unit  
- `CustomerID` — unique customer identifier  
- `Country` — customer location  

---

## 2. Data Cleaning & Transformation

Data preparation was performed using **Python (Pandas)**.

### Key steps:

- Removal of **missing CustomerID values**  
- Filtering out **invalid or negative quantities** (returns, cancellations)  
- Handling **duplicate transactions**  
- Conversion of data types (dates, numeric fields)  
- Creation of **derived features**, including:
  - `order_revenue` (Quantity × UnitPrice)  
  - `order_month` (date truncation for cohort analysis)  

The result is a cleaned dataset suitable for **customer-level aggregation and cohort analysis**.

---

## 3. Data Modeling & Storage

The data was transformed into structured analytical tables using **SQL (PostgreSQL)**.

### Core tables:

- `orders` — order-level dataset (fact table)  
- `customer_features` — customer-level aggregated features (RFM + behavioral metrics)  
- `cohort_retention_long` — cohort retention metrics over time  
- `cohort_summary` — cohort-level aggregates  

The data model supports:
- **Retention analysis**  
- **Churn detection**  
- **Customer segmentation**  

---

## 4. Business Context Simulation

The company name **Grayford Supply** and the associated business case were created specifically for **portfolio purposes**.

This simulation allows the analysis to be presented in a **real-world business context**, including:
- customer lifecycle analysis  
- retention strategy development  
- churn risk identification  

---

## 5. Project Workflow Overview

The project follows a structured analytical workflow:

1. **Data Cleaning (Python)**  
   - preprocessing, validation, feature engineering  

2. **Data Modeling (SQL)**  
   - transformation into analytical tables  
   - cohort and retention calculations  

3. **Analysis & Modeling (Python)**  
   - churn definition  
   - behavioral feature analysis  
   - logistic regression modeling  

4. **Visualization (Tableau)**  
   - retention dashboard  
   - churn drivers dashboard  
   - business insight communication  

---

## 6. Notes & Limitations

- The dataset does not include **true customer lifetime value (CLV)**, therefore proxy metrics are used  
- Returns and cancellations are partially filtered but may still affect revenue calculations  
- The analysis assumes that **inactivity implies churn**, based on a defined threshold  

---