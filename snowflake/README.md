# Snowflake

La partie Snowflake va me servir pour ce projet de data warehouse dans le cloud. L'avantage de Snowflake est notamment le fait que la partie stockage soit séparée de la partie calcul....



### Warehouse 

Le warahouse dans snowflake est le moteur qui exécute les requètes SQL et non pas un entrepôt de donnée. Il s'éteint et se rallume au besoin. Voici comment je l'ai configuré : 

```sql
CREATE WAREHOUSE RETAIL_WH
    WAREHOUSE_SIZE = 'X-SMALL'    -- La plus petite taille (et la moins chère suffisant pour mon projet)
    AUTO_SUSPEND = 60             -- S'éteint après 60 secondes d'inactivité
    AUTO_RESUME = TRUE            -- Se rallume tout seul quand on lance une requête
```

### Rôle



Pour s'assurer de ne pas avoir de problèmes de sécurité, j'ai créé un rôle spécial pour airflow plutôt que de lui donner les droits admins. Ainsi Airflow pourra utiliser le Warehouse et gérer la base de données et c'est tout.

```sql
CREATE ROLE AIRFLOW_ROLE;
GRANT USAGE ON WAREHOUSE RETAIL_WH TO ROLE AIRFLOW_ROLE;
```

### Schémas (Architecture Medallion)

La base `RETAIL_DB` est organisée en trois schémas pour séparer les étapes du traitement :

* **RAW (Bronze)** : Réception des données brutes. Toutes les colonnes sont en `VARCHAR` pour garantir l'ingestion sans erreur, peu importe le formatage d'origine.
* **STAGING (Silver)** : Couche de transformation gérée par dbt. Les données y sont typées (dates, nombres) et les montants convertis en EUR.
* **ANALYTICS (Gold)** : Tables finales agrégées. Contient les indicateurs business (CA mensuel, Top produits) prêts pour la visualisation.

### Ingestion (Stage & File Format)

Pour charger les fichiers, j'utilise un **Stage** comme zone de transit et un **File Format** pour configurer la lecture des CSV.

```sql
CREATE FILE FORMAT RAW.MY_CSV_FORMAT
    TYPE = 'CSV'
    FIELD_DELIMITER = ','
    SKIP_HEADER = 1
    NULL_IF = ('NULL', 'null', '');
```
*Le format définit le séparateur, ignore la ligne d'en-tête et gère les valeurs nulles.*

```sql
CREATE OR REPLACE STAGE RAW.SF_STAGE_SALES
    FILE_FORMAT = RAW.MY_CSV_FORMAT;
```
*Le stage permet de stocker temporairement les fichiers CSV avant de les charger dans la table RAW.*


### Scripts SQL de gestion

* **`init.sql`** : Script d'initialisation. Crée les rôles, le Warehouse, la Database, les schémas et la table source.
* **`clean.sql`** : Script de reset. Supprime les tables et les schémas (y compris les schémas par défauts de dbt) pour repartir d'un environnement propre.

