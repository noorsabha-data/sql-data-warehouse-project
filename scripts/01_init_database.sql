
/*
=============================================================
Create Database and Schemas
=============================================================
Script Purpose:
    This script creates a new database named 'DataWarehouse' after checking if it already exists. 
    If the database exists, it is dropped and recreated. Additionally, the script sets up three schemas 
    within the database: 'bronze', 'silver', and 'gold'.
	
WARNING:
    Running this script will drop the entire 'DataWarehouse' database if it exists. 
    All data in the database will be permanently deleted. Proceed with caution 
    and ensure you have proper backups before running this script.



=============================================================
DATA WAREHOUSE OVERVIEW
=============================================================
What is a Data Warehouse?
    A data warehouse is a subject-oriented, integrated, time-variant, 
    and non-volatile collection of data used to support decision-making.

-------------------------------------------------------------
Steps Involved in Building a Data Warehouse
-------------------------------------------------------------
1. Requirement Analysis
    - Understand business needs and analytical goals.

2. Data Architecture Design
    - Define the overall architecture (data warehouse, lake, etc.).
    - Design system structure similar to a blueprint.

3. Layer Design
    - Bronze Layer: Raw data ingestion
    - Silver Layer: Data cleaning and transformation
    - Gold Layer  : Business-ready data for reporting

4. Separation of Concerns
    - Ingestion handled in Bronze
    - Cleaning and transformation in Silver
    - Business logic and analytics in Gold

-------------------------------------------------------------
Types of Data Architectures
-------------------------------------------------------------

1. Data Warehouse
    - Suitable for structured data
    - Used for reporting and business intelligence

2. Data Lake
    - Stores structured, semi-structured, and unstructured data
    - Suitable for advanced analytics and machine learning

3. Data Lakehouse
    - Combines benefits of data warehouse and data lake
    - Supports both structured and unstructured data

4. Data Mesh
    - Decentralized approach
    - Data is treated as a product owned by domain teams

-------------------------------------------------------------
Project Architecture
-------------------------------------------------------------
    This project follows a Data Warehouse architecture 
    using a Medallion approach (Bronze, Silver, Gold).
*/

-- Navigate to master database
USE master;
GO

-- Drop and recreate 'DataWarehouse' database
IF EXISTS (SELECT 1 FROM sys.databases WHERE name = 'DataWarehouse')
BEGIN
   ALTER DATABASE DataWarehouse SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
   DROP DATABASE DataWarehouse;
END;
GO

CREATE DATABASE DataWarehouse;

-- Use Created database 'DataWarehouse' 
USE DataWarehouse;
GO

-- Create Schemas
CREATE SCHEMA bronze;
GO

CREATE SCHEMA silver;
GO

CREATE SCHEMA gold;
GO

