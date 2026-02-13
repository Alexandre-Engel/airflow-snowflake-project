# Retail Data Pipeline : Airflow, Snowflake & dbt

Ce projet automatise l'ingestion et la transformation des données de ventes pour trois boutiques internationales (Paris, Tokyo, New York). Le pipeline gère le cycle complet : de la réception des CSV bruts à la génération de KPIs financiers.

## Architecture du projet

Le pipeline repose sur une architecture **Medallion** (ELT) intégrée dans Snowflake :

* **Bronze (RAW)** : Ingestion des fichiers CSV tels quels (tout en `VARCHAR`).
* **Silver (STAGING)** : Nettoyage, typage des données, traduction des produits et conversion des devises en EUR.
* **Gold (ANALYTICS)** : Agrégations métiers (Chiffre d'affaires mensuel, classements produits).

## Stack Technique

* **Orchestration** : Airflow (TaskFlow API).
* **Stockage & Calcul** : Snowflake.
* **Transformation** : dbt (modèles, seeds et tests).

## Fonctionnement du Pipeline

Le DAG Airflow `01_ingest_sales_data` exécute les étapes suivantes :

1. **Scan** : Détection des nouveaux CSV dans le dossier `data/inbox/`.
2. **Ingestion** : Upload vers un Stage Snowflake et chargement dans la table `RAW` (via `COPY INTO`).
3. **Archivage** : Déplacement des fichiers traités vers `data/archive/` avec un timestamp.
4. **Transformation (dbt)** :
* `dbt seed` : Chargement des référentiels (taux de change, formats de date par ville, catalogue produits).
* `dbt run` : Exécution des modèles Silver et Gold.
* `dbt test` : Validation de la qualité des données.



## Points clés de l'implémentation

* **Traçabilité** : Le nom du fichier source est conservé dans chaque ligne (`METADATA$FILENAME`) pour identifier la provenance (boutique) et appliquer les règles de gestion spécifiques (devises, formats de date).
* **Modularité** : Les taux de change et les traductions ne sont pas écrits en dur dans le SQL, mais gérés via des fichiers `seeds` (CSV) pour faciliter les mises à jour.
* **Qualité** : Des tests de cohérence vérifient que les montants sont positifs et que les dates extraites correspondent bien au mois indiqué dans le nom du fichier.

## Installation rapide

1. **Snowflake** : Exécuter `snowflake/init.sql` dans un workspace snowflake.
2. **Python** : `pip install -r requirements.txt`.
3. **Airflow** : Configurer la connexion Snowflake dans l'interface, puis lancer via `bash start_airflow.sh`.
4. **dbt** : Configurer le fichier `profiles.yml` avec vos accès Snowflake.

## Commandes utiles

* **Lancer le pipeline** : Déposer un CSV dans `inbox/` et trigger le DAG sur Airflow.
* **Lancer dbt manuellement** : `cd retail_transformation && dbt run`.
* **Voir la doc dbt** : `dbt docs generate && dbt docs serve`.
