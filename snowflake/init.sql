-- =============================================================================
-- Snowflake Infrastructure Setup
-- =============================================================================
-- Execute with ACCOUNTADMIN role
-- Replace YOUR_USERNAME with your Snowflake username
-- =============================================================================

USE ROLE ACCOUNTADMIN;

-- -----------------------------------------------------------------------------
-- 1. WAREHOUSE
-- -----------------------------------------------------------------------------

CREATE OR REPLACE WAREHOUSE RETAIL_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- -----------------------------------------------------------------------------
-- 2. ROLE & PERMISSIONS
-- -----------------------------------------------------------------------------

CREATE ROLE IF NOT EXISTS AIRFLOW_ROLE;
GRANT ROLE AIRFLOW_ROLE TO USER YOUR_USERNAME;
GRANT USAGE ON WAREHOUSE RETAIL_WH TO ROLE AIRFLOW_ROLE;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE AIRFLOW_ROLE;

-- -----------------------------------------------------------------------------
-- 3. DATABASE
-- -----------------------------------------------------------------------------

CREATE DATABASE IF NOT EXISTS RETAIL_DB;
GRANT OWNERSHIP ON DATABASE RETAIL_DB TO ROLE AIRFLOW_ROLE;

-- -----------------------------------------------------------------------------
-- 4. SCHEMAS (Medallion Architecture)
-- -----------------------------------------------------------------------------

USE ROLE AIRFLOW_ROLE;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_DB;

CREATE SCHEMA IF NOT EXISTS RAW;        -- Bronze: Raw data
CREATE SCHEMA IF NOT EXISTS STAGING;    -- Silver: Cleaned data
CREATE SCHEMA IF NOT EXISTS ANALYTICS;  -- Gold: Aggregations

USE SCHEMA RAW;

-- -----------------------------------------------------------------------------
-- 5. FILE FORMAT
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FILE FORMAT RAW.MY_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- -----------------------------------------------------------------------------
-- 6. STAGE
-- -----------------------------------------------------------------------------

CREATE OR REPLACE STAGE RAW.SF_STAGE_SALES
    FILE_FORMAT = RAW.MY_CSV_FORMAT;

-- -----------------------------------------------------------------------------
-- 7. TABLE
-- -----------------------------------------------------------------------------

CREATE OR REPLACE TABLE RAW.SALESDATA_INBOUND (
    ID_SALE             INT,
    SALE_DATE           DATE,
    PRODUCT_NAME        VARCHAR(100),
    CATEGORY            VARCHAR(50),
    UNIT_PRICE          FLOAT,
    QUANTITY            INT,
    TOTAL_AMOUNT        FLOAT,
    SOURCE_FILE_NAME    VARCHAR(255),
    LOAD_TIMESTAMP      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
