/*
===============================================================================
Stored Procedure: gold.load_gold
===============================================================================
Script Purpose:
    Orchestrates the end-to-end ETL process to load the Gold layer from the
    Silver layer. The Gold layer represents a curated, business-ready
    Star Schema optimized for analytics, reporting, and BI consumption.

Overview:
    This procedure performs a full refresh of the Gold layer by truncating
    existing data and reloading dimension and fact tables with transformed,
    cleansed, and integrated data sourced from the Silver layer.

    The resulting model supports:
        - High-performance analytical queries
        - Consistent and reliable reporting
        - Downstream BI tools (Power BI, Tableau, etc.)

Data Model:
    - Dimension Tables:
        • gold.dim_customers
        • gold.dim_products
    - Fact Table:
        • gold.fact_sales
    - Grain:
        • One row per (order_number, product_key)

Execution Flow:
    1. Initialize batch metadata (Batch ID, timestamps)
    2. Truncate target tables (fact → dimensions) to ensure clean reload
    3. Load dimension tables with enriched and standardized data
    4. Load fact table with surrogate key mappings
    5. Capture row counts and execution time for each step
    6. Commit transaction upon success

Key Features:
    - Full refresh strategy using TRUNCATE for simplicity and consistency
    - Surrogate keys managed via IDENTITY columns in dimension tables
    - Robust transaction management (BEGIN TRANSACTION / COMMIT / ROLLBACK)
    - Error handling with TRY...CATCH and detailed diagnostics
    - Execution logging including batch ID, row counts, and load durations
    - Deterministic load order to maintain referential integrity

Data Transformation Rules:
    - Customer gender is derived using prioritized source logic:
        • CRM source preferred when available
        • ERP source used as fallback
    - Product dimension filters out inactive (historical) records
    - Fact table enforces referential integrity via INNER JOINs

Usage:
    EXEC gold.load_gold;

Dependencies:
    - Source tables in Silver layer:
        • silver.crm_cust_info
        • silver.erp_cust_az12
        • silver.erp_loc_a101
        • silver.crm_prd_info
        • silver.erp_px_cat_g1v2
        • silver.crm_sales_details

Assumptions:
    - Silver layer data is fully populated and validated prior to execution
    - Dimension tables are reloaded before fact table to ensure key integrity
    - This procedure is intended for batch execution (not real-time ingestion)

Limitations:
    - Full refresh may not scale efficiently for very large datasets
    - Surrogate keys are regenerated on each run (non-persistent across loads)

Future Enhancements:
    - Implement incremental loading (MERGE / CDC) for improved performance
    - Add Slowly Changing Dimension (SCD Type 2) support
    - Introduce ETL audit/logging tables for persistent monitoring
    - Add data quality validation and anomaly detection checks
===============================================================================
*/


CREATE OR ALTER PROCEDURE gold.load_gold AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    DECLARE 
        @batch_id UNIQUEIDENTIFIER = NEWID(),
        @start_time DATETIME, 
        @end_time DATETIME, 
        @batch_start_time DATETIME, 
        @batch_end_time DATETIME,
        @rows_deleted INT; 
    BEGIN TRY
        BEGIN TRANSACTION;
        
        SET @batch_start_time = GETDATE();
        PRINT '================================================';
        PRINT 'Batch ID: ' + CAST(@batch_id AS NVARCHAR(36));
        PRINT 'Loading Gold Layer';
        PRINT '================================================';
        
        -- ============================================================
        -- Truncating Tables (child to parents)
        -- ============================================================

        PRINT '>> Truncating Table:  gold.fact_sales ';
		TRUNCATE TABLE  gold.fact_sales ;

        PRINT '>> Deleting Table:  gold.dim_customers';
		DELETE FROM gold.dim_customers;
        SET @rows_deleted = @@ROWCOUNT;
        PRINT '>> Rows Deleted: ' + CAST(@rows_deleted AS NVARCHAR(20));

        
        PRINT '>> Deleting Table:  gold.dim_products ';
		DELETE FROM gold.dim_products;
        SET @rows_deleted = @@ROWCOUNT;
        PRINT '>> Rows Deleted: ' + CAST(@rows_deleted AS NVARCHAR(20));

		
        PRINT '------------------------------------------------';
		PRINT 'Loading Dimension Tables';
		PRINT '------------------------------------------------';
        -- ============================================================
        -- Load dim_customers
        -- ============================================================
        SET @start_time = GETDATE();
		PRINT '>> Inserting Data Into:  gold.dim_customers';
        INSERT INTO gold.dim_customers (
            customer_id,
            customer_number,
            first_name,
            last_name,
            country,
            marital_status,
            gender,
            birthdate,
            create_date
        )
        SELECT
            ci.cst_id,
            ci.cst_key,
            ci.cst_firstname,
            ci.cst_lastname,
            la.cntry,
            ci.cst_marital_status,
            CASE 
                WHEN ci.cst_gndr <> 'n/a' THEN ci.cst_gndr
                ELSE COALESCE(ca.gen, 'n/a')
            END AS gender,
            ca.bdate,
            ci.cst_create_date
        FROM silver.crm_cust_info ci
        LEFT JOIN silver.erp_cust_az12 ca
            ON ci.cst_key = ca.cid
        LEFT JOIN silver.erp_loc_a101 la
            ON ci.cst_key = la.cid;
        
        PRINT '>> Rows Inserted: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';
        -- ============================================================
        -- Load dim_products
        -- ============================================================
        SET @start_time = GETDATE();
		PRINT '>> Inserting Data Into:  gold.dim_products ';
        INSERT INTO gold.dim_products (
            product_id,
            product_number,
            product_name,
            category_id,
            category,
            subcategory,
            maintenance,
            cost,
            product_line,
            start_date
        )
        SELECT
            pn.prd_id,
            pn.prd_key,
            pn.prd_nm,
            pn.cat_id,
            pc.cat,
            pc.subcat,
            pc.maintenance,
            pn.prd_cost,
            pn.prd_line,
            pn.prd_start_dt
        FROM silver.crm_prd_info pn
        LEFT JOIN silver.erp_px_cat_g1v2 pc
            ON pn.cat_id = pc.id
        WHERE pn.prd_end_dt IS NULL;
        
        PRINT '>> Rows Inserted: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';
        
        
        PRINT '------------------------------------------------';
		PRINT 'Loading Fact Table';
		PRINT '------------------------------------------------';
        
        -- ============================================================
        -- Load fact_sales
        -- ============================================================
        SET @start_time = GETDATE();
		PRINT '>> Inserting Data Into:  gold.fact_sales ';
        INSERT INTO gold.fact_sales (
            order_number,
            product_key,
            customer_key,
            order_date,
            shipping_date,
            due_date,
            sales_amount,
            quantity,
            price
        )
        SELECT
            sd.sls_ord_num,
            dp.product_key,
            dc.customer_key,
            sd.sls_order_dt,
            sd.sls_ship_dt,
            sd.sls_due_dt,
            sd.sls_sales,
            sd.sls_quantity,
            sd.sls_price
        FROM silver.crm_sales_details sd
        INNER JOIN gold.dim_products dp
            ON sd.sls_prd_key = dp.product_number
        INNER JOIN gold.dim_customers dc
            ON sd.sls_cust_id = dc.customer_id;
        
        PRINT '>> Rows Inserted: ' + CAST(@@ROWCOUNT AS NVARCHAR(20));

		SET @end_time = GETDATE();
        PRINT '>> Load Duration: ' + CAST(DATEDIFF(SECOND, @start_time, @end_time) AS NVARCHAR(20)) + ' seconds';
        PRINT '>> -------------';
        SET @batch_end_time = GETDATE();
        -- ============================================================
        -- Commit Transaction
        -- ============================================================
        COMMIT TRANSACTION;
        PRINT '=========================================='
		PRINT 'Loading Gold Layer is Completed';
        PRINT 'SUCCESS - Batch Completed';
        PRINT 'Batch ID: ' + CAST(@batch_id AS NVARCHAR(36));
        PRINT '   - Total Load Duration: ' + CAST(DATEDIFF(SECOND, @batch_start_time, @batch_end_time) AS NVARCHAR(20)) + ' seconds';
		PRINT '=========================================='
       

    END TRY
    BEGIN CATCH
        IF XACT_STATE() <> 0
            ROLLBACK TRANSACTION;

        PRINT '==========================================';
        PRINT 'ERROR OCCURRED DURING LOADING GOLD LAYER';
        PRINT 'ERROR - Batch Failed';
        PRINT 'Batch ID: ' + CAST(@batch_id AS NVARCHAR(36));
        PRINT 'Error Message: ' + ERROR_MESSAGE();
        PRINT 'Error Number: ' + CAST(ERROR_NUMBER() AS NVARCHAR(20));
        PRINT 'Error State: ' + CAST(ERROR_STATE() AS NVARCHAR(20));
        PRINT '==========================================';

        THROW; 
    END CATCH
END;

-- EXEC gold.load_gold;
