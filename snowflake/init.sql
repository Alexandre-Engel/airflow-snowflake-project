-- Snowflake Setup de l'infrastructure
-- Fichier a exécuter une seule fois pour créer la base de données, les schémas, le stage et la table brute (RAW)

USE ROLE ACCOUNTADMIN;

-- 1. WAREHOUSE

CREATE OR REPLACE WAREHOUSE RETAIL_WH
    WAREHOUSE_SIZE = 'X-SMALL'
    AUTO_SUSPEND = 60
    AUTO_RESUME = TRUE
    INITIALLY_SUSPENDED = TRUE;

-- 2. ROLE & PERMISSIONS

CREATE ROLE IF NOT EXISTS AIRFLOW_ROLE;
GRANT ROLE AIRFLOW_ROLE TO USER YOUR_USERNAME;
GRANT USAGE ON WAREHOUSE RETAIL_WH TO ROLE AIRFLOW_ROLE;
GRANT CREATE DATABASE ON ACCOUNT TO ROLE AIRFLOW_ROLE;

-- 3. DATABASE

CREATE DATABASE IF NOT EXISTS RETAIL_DB;
GRANT OWNERSHIP ON DATABASE RETAIL_DB TO ROLE AIRFLOW_ROLE;

-- 4. SCHEMAS (Architecture Medallion)

USE ROLE AIRFLOW_ROLE;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_DB;

CREATE SCHEMA IF NOT EXISTS RAW;        -- Bronze: Données d'ingestion, tout en VARCHAR, sans transformation
CREATE SCHEMA IF NOT EXISTS STAGING;    -- Silver: Données typées, nettoyées, augmentées, prêtes pour les transformations
CREATE SCHEMA IF NOT EXISTS ANALYTICS;  -- Gold: Agrégations

USE SCHEMA RAW;

-- 5. FORMAT DE FICHIER
-- Ce format sera utilisé pour l'ingestion des fichiers CSV dans le stage Snowflake.

CREATE OR REPLACE FILE FORMAT RAW.MY_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    FIELD_OPTIONALLY_ENCLOSED_BY = '"'
    NULL_IF = ('NULL', 'null', '');

-- 6. STAGE
-- Le stage permet de stocker temporairement les fichiers CSV avant de les charger dans la table RAW.

CREATE OR REPLACE STAGE RAW.SF_STAGE_SALES
    FILE_FORMAT = RAW.MY_CSV_FORMAT;

-- 7. TABLE (Bronze : tout en VARCHAR, données brutes sans transformation)
-- Le typage (DATE, NUMBER, INT) se fait dans la couche Silver via dbt.

CREATE TABLE IF NOT EXISTS RAW.SALESDATA_INBOUND (
    ID_SALE             VARCHAR,
    SALE_DATE           VARCHAR,
    PRODUCT_NAME        VARCHAR,
    CATEGORY            VARCHAR,
    UNIT_PRICE          VARCHAR,
    QUANTITY            VARCHAR,
    TOTAL_AMOUNT        VARCHAR,
    SOURCE_FILE_NAME    VARCHAR,
    LOAD_TIMESTAMP      TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
);
