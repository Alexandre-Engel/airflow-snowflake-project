{{ config(materialized='table') }}

SELECT
    nom_produit,
    categorie,
    SUM(quantite) as total_unites_vendues,
    SUM(montant_total_eur) as total_ca_genere_eur,
    RANK() OVER (ORDER BY SUM(montant_total_eur) DESC) as rang_ca
FROM {{ ref('stg_ventes') }}
GROUP BY 1, 2