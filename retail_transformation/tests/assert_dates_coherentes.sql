
-- Ce test détecte les erreurs de parsing de date (ex: 09/02 interprété comme le 2 septembre au lieu du 9 février).
-- Pour se faire, on utilise le mois contenu dans le nom du fichier source (ex: sales_paris_february.csv) comme référence.

WITH mois_mapping AS (
    SELECT 1 AS num_mois, 'january' AS nom_mois UNION ALL
    SELECT 2, 'february' UNION ALL
    SELECT 3, 'march' UNION ALL
    SELECT 4, 'april' UNION ALL
    SELECT 5, 'may' UNION ALL
    SELECT 6, 'june' UNION ALL
    SELECT 7, 'july' UNION ALL
    SELECT 8, 'august' UNION ALL
    SELECT 9, 'september' UNION ALL
    SELECT 10, 'october' UNION ALL
    SELECT 11, 'november' UNION ALL
    SELECT 12, 'december'
),

ventes_avec_mois AS (
    SELECT
        v.id_vente,
        v.date_vente,
        v.source_file_name,
        MONTH(v.date_vente) AS mois_date_parsee,
        m.nom_mois AS mois_attendu_fichier
    FROM {{ ref('stg_ventes') }} v
    LEFT JOIN mois_mapping m ON MONTH(v.date_vente) = m.num_mois
)

SELECT
    id_vente,
    date_vente,
    source_file_name,
    mois_date_parsee,
    mois_attendu_fichier
FROM ventes_avec_mois
WHERE 
    -- Le nom du fichier devrait contenir le mois correspondant à la date
    NOT CONTAINS(LOWER(source_file_name), mois_attendu_fichier)