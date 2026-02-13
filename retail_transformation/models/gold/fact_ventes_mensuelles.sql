{{ config(materialized='table') }}

WITH silver_sales AS (
    SELECT * FROM {{ ref('stg_ventes') }}
)

SELECT
    DATE_TRUNC('month', date_vente) as mois,
    nom_boutique,
    ville,
    pays,
    SUM(montant_total_eur) as ca_mensuel_eur,
    COUNT(id_vente) as nombre_de_ventes
FROM silver_sales
GROUP BY 1, 2, 3, 4