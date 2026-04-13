/*
===============================================================================
Script: Silver Layer Data Quality Checks
===============================================================================
Script Purpose:
    This script performs comprehensive data quality validations on the 
    Silver layer to ensure data consistency, accuracy, and reliability 
    before loading into the Gold layer.

    The checks include:
        - Primary key integrity (NULLs, duplicates)
        - String standardization (trimming, formatting)
        - Numerical validations (negative or NULL values)
        - Date validity and logical ordering
        - Business rule validation (e.g., sales = quantity * price)
        - Referential integrity across related tables

Key Features:
    - PASS / FAIL status messages using PRINT statements
    - Safe validation logic using EXISTS / NOT EXISTS
    - Structured and modular validation blocks
    - Designed for integration into ETL pipelines

Usage Notes:
    - Execute after Silver layer load
    - Investigate any FAIL messages before proceeding to Gold layer
    - Can be extended into automated monitoring or alerting

===============================================================================
*/

SET NOCOUNT ON;

PRINT '================================================';
PRINT 'Running Silver Layer Data Quality Checks';
PRINT '================================================';

-- ====================================================================
-- CHECK: crm_cust_info
-- ====================================================================
PRINT 'Checking: silver.crm_cust_info';

-- Primary Key Check
IF EXISTS (
    SELECT 1
    FROM silver.crm_cust_info
    GROUP BY cst_id
    HAVING COUNT(*) > 1 OR cst_id IS NULL
)
    PRINT 'FAIL: Duplicate or NULL customer IDs found';
ELSE
    PRINT 'PASS: Customer ID integrity';

-- Unwanted Spaces
IF EXISTS (
    SELECT 1
    FROM silver.crm_cust_info
    WHERE cst_key <> TRIM(cst_key)
)
    PRINT 'FAIL: Untrimmed customer keys found';
ELSE
    PRINT 'PASS: Customer key formatting';

-- ====================================================================
-- CHECK: crm_prd_info
-- ====================================================================
PRINT 'Checking: silver.crm_prd_info';

-- Primary Key Check
IF EXISTS (
    SELECT 1
    FROM silver.crm_prd_info
    GROUP BY prd_id
    HAVING COUNT(*) > 1 OR prd_id IS NULL
)
    PRINT 'FAIL: Duplicate or NULL product IDs found';
ELSE
    PRINT 'PASS: Product ID integrity';

-- Cost Validation
IF EXISTS (
    SELECT 1
    FROM silver.crm_prd_info
    WHERE prd_cost < 0 OR prd_cost IS NULL
)
    PRINT 'FAIL: Invalid product cost values';
ELSE
    PRINT 'PASS: Product cost validation';

-- Date Logic Check
IF EXISTS (
    SELECT 1
    FROM silver.crm_prd_info
    WHERE prd_end_dt < prd_start_dt
)
    PRINT 'FAIL: Invalid product date ranges';
ELSE
    PRINT 'PASS: Product date validation';

-- ====================================================================
-- CHECK: crm_sales_details
-- ====================================================================
PRINT 'Checking: silver.crm_sales_details';

-- Date Order Check
IF EXISTS (
    SELECT 1
    FROM silver.crm_sales_details
    WHERE sls_order_dt > sls_ship_dt 
       OR sls_order_dt > sls_due_dt
)
    PRINT 'FAIL: Invalid sales date sequence';
ELSE
    PRINT 'PASS: Sales date validation';

-- Business Rule Check
IF EXISTS (
    SELECT 1
    FROM silver.crm_sales_details
    WHERE sls_sales <> sls_quantity * sls_price
       OR sls_sales IS NULL 
       OR sls_quantity IS NULL 
       OR sls_price IS NULL
       OR sls_sales <= 0 
       OR sls_quantity <= 0 
       OR sls_price <= 0
)
    PRINT 'FAIL: Sales calculation mismatch';
ELSE
    PRINT 'PASS: Sales calculation integrity';

-- ====================================================================
-- CHECK: erp_cust_az12
-- ====================================================================
PRINT 'Checking: silver.erp_cust_az12';

-- Birthdate Range Check
IF EXISTS (
    SELECT 1
    FROM silver.erp_cust_az12
    WHERE bdate < '1926-01-01' OR bdate > GETDATE()
)
    PRINT 'FAIL: Invalid customer birthdates';
ELSE
    PRINT 'PASS: Customer birthdate validation';

-- Referential Integrity Check
IF EXISTS (
    SELECT 1
    FROM silver.erp_cust_az12 az
    WHERE NOT EXISTS (
        SELECT 1
        FROM silver.crm_cust_info ci
        WHERE ci.cst_key = az.cid
    )
)
    PRINT 'FAIL: Orphan customer records found (ERP)';
ELSE
    PRINT 'PASS: Customer referential integrity';

-- ====================================================================
-- CHECK: erp_loc_a101
-- ====================================================================
PRINT 'Checking: silver.erp_loc_a101';

IF EXISTS (
    SELECT 1
    FROM silver.erp_loc_a101 la
    WHERE NOT EXISTS (
        SELECT 1
        FROM silver.crm_cust_info ci
        WHERE ci.cst_key = la.cid
    )
)
    PRINT 'FAIL: Orphan location records found';
ELSE
    PRINT 'PASS: Location referential integrity';

-- ====================================================================
-- CHECK: erp_px_cat_g1v2
-- ====================================================================
PRINT 'Checking: silver.erp_px_cat_g1v2';

-- Referential Integrity Check
IF EXISTS (
    SELECT 1
    FROM silver.erp_px_cat_g1v2 pc
    WHERE NOT EXISTS (
        SELECT 1
        FROM silver.crm_prd_info pr
        WHERE pr.cat_id = pc.id
    )
)
    PRINT 'FAIL: Orphan product categories found';
ELSE
    PRINT 'PASS: Product category integrity';

-- String Cleanliness
IF EXISTS (
    SELECT 1
    FROM silver.erp_px_cat_g1v2
    WHERE cat <> TRIM(cat) 
       OR subcat <> TRIM(subcat) 
       OR maintenance <> TRIM(maintenance)
)
    PRINT 'FAIL: Untrimmed category fields found';
ELSE
    PRINT 'PASS: Category formatting';

-- ====================================================================
-- FINAL SUMMARY
-- ====================================================================
PRINT '================================================';
PRINT 'Data Quality Checks Completed';
PRINT 'Review any FAIL messages above before proceeding';
PRINT '================================================';