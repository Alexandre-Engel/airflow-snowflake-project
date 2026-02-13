-- Ce script supprime toutes les données et les schémas parasites
-- créés par dbt avant la correction de la macro generate_schema_name.
-- Requêtes aussi utilisés pour nettoyer la base avant de relancer les tests dbt.

USE ROLE AIRFLOW_ROLE;
USE WAREHOUSE RETAIL_WH;
USE DATABASE RETAIL_DB;

-- 1. Supprimer les schémas parasites (créés par le bug dbt, plus besoin après correction de la macro)

DROP SCHEMA IF EXISTS RETAIL_DB.STAGING_STAGING CASCADE;
DROP SCHEMA IF EXISTS RETAIL_DB.STAGING_ANALYTICS CASCADE;

-- 2. Vider les tables existantes

-- Bronze : supprimer la table RAW (sera recréée par init.sql)
DROP TABLE IF EXISTS RETAIL_DB.RAW.SALESDATA_INBOUND;

-- Silver : supprimer les tables de staging (recréées par les modèles dbt)
DROP TABLE IF EXISTS RETAIL_DB.STAGING.STG_VENTES;
DROP TABLE IF EXISTS RETAIL_DB.STAGING.MY_FIRST_DBT_MODEL;

-- Gold : supprimer les tables d'analytics (recréées par les modèles dbt)
DROP TABLE IF EXISTS RETAIL_DB.ANALYTICS.FACT_VENTES_MENSUELLES;
DROP TABLE IF EXISTS RETAIL_DB.ANALYTICS.TOP_PRODUITS_PERFORMANCE;

-- Seeds dbt : supprimer les tables de référence (recréées par les seeds dbt)
DROP TABLE IF EXISTS RETAIL_DB.STAGING.CATALOGUE_PRODUITS;
DROP TABLE IF EXISTS RETAIL_DB.STAGING.DIM_BOUTIQUES;

-- 3. Nettoyer le stage Snowflake

REMOVE @RETAIL_DB.RAW.SF_STAGE_SALES;
