{{ config(materialized='table') }}

WITH raw_sales AS (
    -- On récupère les ventes brutes
    SELECT * FROM {{ source('retail_raw', 'salesdata_inbound') }}
),

catalogue AS (
    -- On récupère notre catalogue importé via dbt seed
    SELECT * FROM {{ ref('catalogue_produits') }}
),

joined_data AS (
    SELECT
        s.ID_SALE::INT as id_vente,
        s.SALE_DATE::DATE as date_vente,
        
        -- On récupère les traductions du catalogue grâce au JOIN
        COALESCE(c.nom_produit_francais, s.PRODUCT_NAME) as nom_produit,
        COALESCE(c.categorie_francais, s.CATEGORY) as categorie,
        
        s.UNIT_PRICE::NUMBER(10,2) as prix_unitaire_local,
        s.QUANTITY::INT as quantite,
        
        -- Calcul du montant local
        (s.UNIT_PRICE * s.QUANTITY) as montant_total_local,

        -- Détermination de la devise et du taux (on pourra brancher l'API plus tard)
        CASE 
            WHEN s.SOURCE_FILE_NAME LIKE '%tokyo%' THEN 'JPY'
            WHEN s.SOURCE_FILE_NAME LIKE '%new-york%' THEN 'USD'
            ELSE 'EUR'
        END as devise,

        -- Conversion en EUR
        CASE 
            WHEN s.SOURCE_FILE_NAME LIKE '%tokyo%' THEN (s.UNIT_PRICE * s.QUANTITY) * 0.0061
            WHEN s.SOURCE_FILE_NAME LIKE '%new-york%' THEN (s.UNIT_PRICE * s.QUANTITY) * 0.92
            ELSE (s.UNIT_PRICE * s.QUANTITY)
        END as montant_total_eur,

        -- Logique pour déterminer la boutique, ville et pays via le nom du fichier
        CASE 
            WHEN SOURCE_FILE_NAME LIKE '%paris%' THEN 'Boutique Paris Centre'
            WHEN SOURCE_FILE_NAME LIKE '%tokyo%' THEN 'Boutique Tokyo Shibuya'
            WHEN SOURCE_FILE_NAME LIKE '%new-york%' THEN 'Boutique NYC Times Square'
            ELSE 'Inconnu'
        END as nom_boutique,

        CASE 
            WHEN SOURCE_FILE_NAME LIKE '%paris%' THEN 'Paris'
            WHEN SOURCE_FILE_NAME LIKE '%tokyo%' THEN 'Tokyo'
            WHEN SOURCE_FILE_NAME LIKE '%new-york%' THEN 'New-York'
            ELSE 'Inconnu'
        END as ville,

        CASE 
            WHEN SOURCE_FILE_NAME LIKE '%paris%' THEN 'France'
            WHEN SOURCE_FILE_NAME LIKE '%tokyo%' THEN 'Japon'
            WHEN SOURCE_FILE_NAME LIKE '%new-york%' THEN 'USA'
            ELSE 'Inconnu'
        END as pays

    FROM raw_sales s
    LEFT JOIN catalogue c ON UPPER(s.PRODUCT_NAME) = UPPER(c.nom_produit_anglais)
)

SELECT * FROM joined_data