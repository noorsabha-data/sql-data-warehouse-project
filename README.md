# 📊 SQL Data Warehouse Project

## 🚀 Overview

This project demonstrates the design and implementation of a modern **data warehouse** using SQL Server. It follows a layered architecture (**Bronze → Silver → Gold**) to transform raw data into a clean, business-ready format for analytics and reporting.

The final output is a **star schema** optimized for business intelligence tools such as Power BI and Tableau.

---

## 🏗️ Architecture

### 🔹 Bronze Layer (Raw Data)

* Stores raw data from CRM and ERP systems
* Minimal transformations applied
* Serves as the ingestion layer

### 🔹 Silver Layer (Cleaned Data)

* Data cleansing and standardization
* Joins and transformations applied
* Prepares structured data for analytics

### 🔹 Gold Layer (Business Layer)

* Star schema design:

  * Fact table: `fact_sales`
  * Dimension tables: `dim_customers`, `dim_products`
* Optimized for reporting and analytics

---

## ⚙️ ETL Pipeline

The project includes stored procedures to automate data movement:

* **Silver Layer**

  * Data cleaning and transformation
* **Gold Layer**

  * Loads dimension tables
  * Loads fact table with surrogate keys
  * Includes logging, error handling, and performance tracking

---

## 📊 Data Model (Star Schema)

**Fact Table**

* `fact_sales`

  * Measures: sales_amount, quantity, price

**Dimension Tables**

* `dim_customers`
* `dim_products`

**Grain**

* One row per `(order_number, product)`

---

## 📈 Reporting Layer

A reporting view is created:

* `vw_sales_report`

This view provides:

* Customer attributes (name, gender, country)
* Product attributes (category, subcategory)
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

## 🧰 Tech Stack

* SQL Server
* T-SQL
* Data Warehousing Concepts (Star Schema, ETL)

---

## 🔥 Key Features

* Layered architecture (Bronze → Silver → Gold)
* Star schema design for analytics
* Surrogate keys and referential integrity
* Stored procedures for ETL automation
* Logging and error handling
* Reporting view for BI tools

---

## 🚧 Future Improvements

* Incremental loading (MERGE / CDC)
* Slowly Changing Dimensions (SCD Type 2)
* ETL audit/logging tables
* Power BI dashboard integration

---

## 👤 Author

Your Name
