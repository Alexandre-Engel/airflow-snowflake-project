
-- Ce test vérifie que tous les montants en EUR sont strictement positifs.
-- Un montant négatif ou nul indiquerait une erreur dans les données.

SELECT
    id_vente,
    date_vente,
    nom_produit,
    montant_total_eur,
    nom_boutique
FROM {{ ref('stg_ventes') }}
WHERE montant_total_eur <= 0
