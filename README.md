# 📊 SQL Data Warehouse Project

## 🚀 Overview

This project demonstrates the end-to-end design and implementation of a **modern data warehouse** using SQL Server.

It transforms raw CRM and ERP data into a **clean, structured, and analytics-ready data model** using a layered architecture (**Bronze → Silver → Gold**).

The final output is a **star schema** optimized for business intelligence tools such as Power BI and Tableau, enabling efficient reporting and data-driven decision-making.

---

## 📂 Data Sources

This project uses CRM and ERP datasets as input for the data warehouse pipeline.

* Source systems:

  * CRM data (`datasets/source_crm`)
  * ERP data (`datasets/source_erp`)

> ⚠️ Raw CSV files are not included due to repository size and best practices.

---

## 🏗️ Architecture

### 🔹 Bronze Layer (Raw Data)

* Stores raw data from source systems
* Minimal transformation applied
* Acts as the ingestion layer

### 🔹 Silver Layer (Cleaned Data)

* Data cleansing and standardization
* Joins and transformations applied
* Prepares structured data for downstream processing

### 🔹 Gold Layer (Business Layer)

* Implements a **star schema**:

  * Fact table: `fact_sales`
  * Dimension tables: `dim_customers`, `dim_products`
* Optimized for analytics and reporting

---

## ⚙️ ETL Pipeline

Automated using stored procedures:

### Silver Layer

* Cleans and standardizes raw data
* Resolves inconsistencies across source systems

### Gold Layer

* Loads dimension tables
* Maps surrogate keys
* Loads fact table
* Includes:

  * Logging
  * Error handling (`TRY...CATCH`)
  * Performance tracking

---

## 📊 Data Model (Star Schema)

### Fact Table

* `fact_sales`

  * Measures: `sales_amount`, `quantity`, `price`

### Dimension Tables

* `dim_customers`
* `dim_products`

### Grain

* One row per `(order_number, product_key)`

---

## 📈 Reporting Layer

A reporting view is created:

* `vw_sales_report`

This view combines fact and dimension tables to provide:

* Customer insights (name, gender, country)
* Product insights (category, subcategory)
* Sales metrics (revenue, quantity, price)
* Derived metrics (profit, profit margin)

---

## 💡 Sample Queries

```sql
-- Top 10 products by revenue
SELECT TOP 10 product_name, SUM(sales_amount) AS revenue
FROM gold.vw_sales_report
GROUP BY product_name
ORDER BY revenue DESC;

-- Revenue by country
SELECT country, SUM(sales_amount) AS revenue
FROM gold.vw_sales_report
GROUP BY country
ORDER BY revenue DESC;

-- Monthly sales trend
SELECT 
    FORMAT(order_date, 'yyyy-MM') AS month,
    SUM(sales_amount) AS revenue
FROM gold.vw_sales_report
GROUP BY FORMAT(order_date, 'yyyy-MM')
ORDER BY month;
```

---

## ✅ Data Quality Checks

Implemented validation scripts across Silver and Gold layers to ensure:

* No duplicate or NULL primary keys
* Clean and standardized data
* Valid date ranges and business rules
* Referential integrity between fact and dimension tables
* Correct fact table grain `(order_number, product_key)`

All checks return **PASS / FAIL indicators**, enabling reliable data validation before reporting.

---

## 🧰 Tech Stack

* SQL Server
* T-SQL
* Data Warehousing Concepts (ETL, Star Schema)

---

## 🔥 Key Features

* Layered architecture (Bronze → Silver → Gold)
* Star schema optimized for analytics
* Surrogate key implementation
* Automated ETL pipelines using stored procedures
* Logging and error handling
* Data quality validation framework
* Reporting view for BI consumption

---

## 🚧 Future Improvements

* Incremental loading (MERGE / CDC)
* Slowly Changing Dimensions (SCD Type 2)
* ETL audit and monitoring tables
* Power BI dashboard integration

---

## 👤 Author

**Noorsabha Qureshi**
