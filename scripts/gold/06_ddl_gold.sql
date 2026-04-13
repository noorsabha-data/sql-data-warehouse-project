/*
===============================================================================
DDL Script: Gold Layer (Star Schema) - Table Creation
===============================================================================
Script Purpose:
    This script creates the physical tables for the Gold layer of the data 
    warehouse. The Gold layer represents the final, business-ready data model 
    structured as a Star Schema.

    It includes:
        - Dimension tables (e.g., customers, products)
        - Fact table (sales transactions)

    These tables are designed to support:
        - Analytical queries
        - Business intelligence reporting
        - High-performance data access

Key Features:
    - Surrogate keys (IDENTITY) for all dimensions and fact table
    - Enforced referential integrity using foreign key constraints
    - Data quality controls via NOT NULL and UNIQUE constraints
    - Optimized query performance through indexing
    - Clearly defined grain for the fact table (order_number + product_key)

Usage:
    - Execute this script to initialize or reset the Gold layer schema
    - Typically run after the Silver layer has been populated
    - Serves as the foundation for downstream reporting and analytics

Notes:
    - This script creates physical tables (not views) to ensure data stability,
      consistency, and performance at scale
    - Designed for extensibility (e.g., adding dim_date, incremental loads)

===============================================================================
*/

-- =============================================================================
-- Create Dimension: gold.dim_customers
-- =============================================================================
IF OBJECT_ID('gold.dim_customers', 'U') IS NOT NULL
    DROP TABLE gold.dim_customers;
GO

CREATE TABLE gold.dim_customers (
    customer_key INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT,
    customer_number NVARCHAR(50),
    first_name NVARCHAR(100),
    last_name NVARCHAR(100),
    country NVARCHAR(50),
    marital_status NVARCHAR(20),
    gender NVARCHAR(10),
    birthdate DATE,
    create_date DATE
);
GO

-- =============================================================================
-- Create Dimension: gold.dim_products
-- =============================================================================
IF OBJECT_ID('gold.dim_products', 'U') IS NOT NULL
    DROP TABLE gold.dim_products;
GO

CREATE TABLE gold.dim_products (
    product_key INT IDENTITY(1,1) PRIMARY KEY,
    product_id INT,
    product_number NVARCHAR(50),
    product_name NVARCHAR(255),
    category_id NVARCHAR(50),
    category NVARCHAR(100),
    subcategory NVARCHAR(100),
    maintenance NVARCHAR(100),
    cost DECIMAL(10,2),
    product_line NVARCHAR(50),
    start_date DATE
);
GO

-- =============================================================================
-- Create Fact Table: gold.fact_sales
-- =============================================================================
IF OBJECT_ID('gold.fact_sales', 'U') IS NOT NULL
    DROP TABLE gold.fact_sales;
GO

CREATE TABLE gold.fact_sales (
    fact_key INT IDENTITY(1,1) PRIMARY KEY,

    order_number NVARCHAR(50) NOT NULL,
    product_key INT NOT NULL,
    customer_key INT NOT NULL,
    
    order_date DATE,
    shipping_date DATE,
    due_date DATE,
    
    sales_amount DECIMAL(12,2) NOT NULL,
    quantity INT NOT NULL,
    price DECIMAL(12,2),
    load_date DATETIME DEFAULT GETDATE(),

    CONSTRAINT fk_product
        FOREIGN KEY (product_key) 
        REFERENCES gold.dim_products(product_key),
    CONSTRAINT fk_customer
        FOREIGN KEY (customer_key) 
        REFERENCES gold.dim_customers(customer_key),
    CONSTRAINT uq_fact 
        UNIQUE (order_number, product_key)   

);
GO

-- =============================================================================
-- Creating Indexes
-- =============================================================================
CREATE INDEX idx_fact_product ON gold.fact_sales(product_key);
CREATE INDEX idx_fact_customer ON gold.fact_sales(customer_key);
CREATE INDEX idx_fact_order_product 
    ON gold.fact_sales(order_number, product_key);