/*
===============================================================================
Script: Gold Layer Data Quality Checks
===============================================================================
Script Purpose:
    This script performs data quality validations on the Gold layer to ensure 
    the data model is reliable, consistent, and ready for analytical use.

    The checks include:
        - Surrogate key uniqueness in dimension tables
        - Referential integrity between fact and dimension tables
        - Fact table grain validation
        - Detection of orphan or missing dimension references

Key Features:
    - PASS / FAIL validation messages
    - Structured checks by table
    - Ensures star schema integrity
    - Designed for integration into ETL workflows

Usage Notes:
    - Execute after Gold layer load
    - Investigate any FAIL messages before reporting/BI usage
===============================================================================
*/
USE DataWarehouse;  -- or your actual DB name
GO
SET NOCOUNT ON;

PRINT '================================================';
PRINT 'Running Gold Layer Data Quality Checks';
PRINT '================================================';

-- ====================================================================
-- CHECK: dim_customers
-- ====================================================================
PRINT 'Checking: gold.dim_customers';

-- Surrogate Key Uniqueness
IF EXISTS (
    SELECT 1
    FROM gold.dim_customers
    GROUP BY customer_key
    HAVING COUNT(*) > 1
)
    PRINT 'FAIL: Duplicate customer_key values found';
ELSE
    PRINT 'PASS: Customer key uniqueness';

-- ====================================================================
-- CHECK: dim_products
-- ====================================================================
PRINT 'Checking: gold.dim_products';

-- Surrogate Key Uniqueness
IF EXISTS (
    SELECT 1
    FROM gold.dim_products
    GROUP BY product_key
    HAVING COUNT(*) > 1
)
    PRINT 'FAIL: Duplicate product_key values found';
ELSE
    PRINT 'PASS: Product key uniqueness';

-- ====================================================================
-- CHECK: fact_sales
-- ====================================================================
PRINT 'Checking: gold.fact_sales';

-- Referential Integrity: Customer
IF EXISTS (
    SELECT 1
    FROM gold.fact_sales f
    WHERE NOT EXISTS (
        SELECT 1
        FROM gold.dim_customers c
        WHERE c.customer_key = f.customer_key
    )
)
    PRINT 'FAIL: Orphan customer_key in fact_sales';
ELSE
    PRINT 'PASS: Customer referential integrity';

-- Referential Integrity: Product
IF EXISTS (
    SELECT 1
    FROM gold.fact_sales f
    WHERE NOT EXISTS (
        SELECT 1
        FROM gold.dim_products p
        WHERE p.product_key = f.product_key
    )
)
    PRINT 'FAIL: Orphan product_key in fact_sales';
ELSE
    PRINT 'PASS: Product referential integrity';

-- ====================================================================
-- CHECK: Fact Table Grain
-- ====================================================================
PRINT 'Checking: fact_sales grain (order_number + product_key)';

IF EXISTS (
    SELECT order_number, product_key
    FROM gold.fact_sales
    GROUP BY order_number, product_key
    HAVING COUNT(*) > 1
)
    PRINT 'FAIL: Duplicate grain detected in fact_sales';
ELSE
    PRINT 'PASS: Fact table grain is consistent';

-- ====================================================================
-- CHECK: Basic Measures Validation
-- ====================================================================
PRINT 'Checking: sales metrics validity';

IF EXISTS (
    SELECT 1
    FROM gold.fact_sales
    WHERE sales_amount <= 0 
       OR quantity <= 0 
       OR price <= 0
       OR sales_amount IS NULL
       OR quantity IS NULL
       OR price IS NULL
)
    PRINT 'FAIL: Invalid sales metrics detected';
ELSE
    PRINT 'PASS: Sales metrics validation';

-- ====================================================================
-- FINAL SUMMARY
-- ====================================================================
PRINT '================================================';
PRINT 'Gold Layer Data Quality Checks Completed';
PRINT 'Review any FAIL messages above';
PRINT '================================================';