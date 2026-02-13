{{ config(materialized='table') }}

WITH raw_sales AS (
    -- Bronze : données brutes, tout est en VARCHAR
    SELECT * FROM {{ source('retail_raw', 'salesdata_inbound') }}
),

catalogue AS (
    -- Référentiel produits : traductions anglais → français
    SELECT * FROM {{ ref('catalogue_produits') }}
),

boutiques AS (
    -- Référentiel boutiques : mapping fichier → boutique/ville/pays/devise/taux/format_date
    -- Pour ajouter une nouvelle boutique, il suffit d'ajouter une ligne dans seeds/dim_boutiques.csv
    SELECT * FROM {{ ref('dim_boutiques') }}
),

joined_data AS (
    SELECT
        s.ID_SALE::INT as id_vente,

        -- Conversion de la date selon le format de la boutique source
        -- Ex: Paris = DD/MM/YYYY, Tokyo = YYYY/MM/DD, New York = MM/DD/YYYY
        TO_DATE(s.SALE_DATE, b.format_date) as date_vente,

        -- Traduction des noms via le catalogue (anglais → français)
        -- COALESCE : prend la traduction FR si elle existe, sinon garde le nom anglais original
        COALESCE(c.nom_produit_francais, s.PRODUCT_NAME) as nom_produit,
        COALESCE(c.categorie_francais, s.CATEGORY) as categorie,

        s.UNIT_PRICE::NUMBER(10,2) as prix_unitaire_local,
        s.QUANTITY::INT as quantite,

        -- Montant local recalculé à partir des valeurs typées
        (s.UNIT_PRICE::NUMBER(10,2) * s.QUANTITY::INT) as montant_total_local,

        -- Devise et conversion en EUR via le référentiel boutiques
        -- COALESCE : si la boutique n'est pas trouvée, on met EUR par défaut
        COALESCE(b.devise, 'EUR') as devise,
        (s.UNIT_PRICE::NUMBER(10,2) * s.QUANTITY::INT) * COALESCE(b.taux_vers_eur, 1.0) as montant_total_eur,

        -- Infos boutique via le référentiel
        COALESCE(b.nom_boutique, 'Inconnu') as nom_boutique,
        COALESCE(b.ville, 'Inconnu') as ville,
        COALESCE(b.pays, 'Inconnu') as pays

    FROM raw_sales s
    LEFT JOIN catalogue c ON UPPER(s.PRODUCT_NAME) = UPPER(c.nom_produit_anglais)
    LEFT JOIN boutiques b ON s.SOURCE_FILE_NAME LIKE '%' || b.pattern_fichier || '%'
)

SELECT * FROM joined_data