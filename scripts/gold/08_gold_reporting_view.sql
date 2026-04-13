/*
===============================================================================
DDL Script: Create Reporting View (Gold Layer)
===============================================================================
Script Purpose:
    This script creates a consolidated reporting view for analytics and 
    business intelligence.

    The view combines the Gold layer fact and dimension tables into a single,
    denormalized dataset that is easy to query for reporting tools such as 
    Power BI, Tableau, or Excel.

    It provides:
        - Sales metrics (revenue, quantity, price)
        - Customer attributes (name, gender, country)
        - Product attributes (category, subcategory, product name)
        - Date fields for time-based analysis

Key Features:
    - Simplifies complex joins into a single view
    - Optimized for read-heavy analytical queries
    - Provides a business-friendly column naming convention
    - Ensures consistent grain: one row per (order_number + product)

Usage:
    SELECT * FROM gold.vw_sales_report;

Notes:
    - Built on top of physical Gold tables (not views)
    - Can be extended with additional dimensions (e.g., dim_date)
    - Ideal for dashboards and ad-hoc analysis
===============================================================================
*/

IF OBJECT_ID('gold.vw_sales_report', 'V') IS NOT NULL
    DROP VIEW gold.vw_sales_report;
GO

CREATE VIEW gold.vw_sales_report AS
SELECT
    -- ============================================================
    -- Order Information
    -- ============================================================
    f.order_number,
    f.order_date,
    f.shipping_date,
    f.due_date,

    -- ============================================================
    -- Customer Information
    -- ============================================================
    c.customer_key,
    c.customer_id,
    c.customer_number,
    c.first_name,
    c.last_name,
    CONCAT(c.first_name, ' ', c.last_name) AS full_name,
    c.gender,
    c.marital_status,
    c.country,
    c.birthdate,
    c.create_date AS customer_create_date,

    -- ============================================================
    -- Product Information
    -- ============================================================
    p.product_key,
    p.product_id,
    p.product_number,
    p.product_name,
    p.category,
    p.subcategory,
    p.product_line,
    p.maintenance,
    p.cost,

    -- ============================================================
    -- Sales Metrics
    -- ============================================================
    f.sales_amount,
    f.quantity,
    f.price,

    -- ============================================================
    -- Derived Metrics
    -- ============================================================
    (f.sales_amount - (f.quantity * p.cost)) AS profit,
    CASE 
        WHEN f.sales_amount = 0 THEN 0
        ELSE (f.sales_amount - (f.quantity * p.cost)) / f.sales_amount
    END AS profit_margin

FROM gold.fact_sales f
INNER JOIN gold.dim_customers c
    ON f.customer_key = c.customer_key
INNER JOIN gold.dim_products p
    ON f.product_key = p.product_key;
GO

