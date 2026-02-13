# DBT

DBT (data build tool) me permet de gérer toute la logique de transformation SQL à l'intérieur de Snowflake. Le projet est structuré pour transformer les données brutes du schéma `RAW` en tables exploitables dans `STAGING` et `ANALYTICS`.

## Structure du projet

* **`models/`** : Contient la logique SQL divisée en deux couches (Silver/Gold).
* **`seeds/`** : Fichiers CSV (boutiques, catalogue) chargés directement en tables de référence.
* **`tests/`** : Scripts SQL de validation des données.
* **`macros/`** : Fonctions personnalisées (ex: gestion propre des noms de schémas).

## Logique de Transformation

### Couche Silver (`stg_ventes.sql`)

Nettoyage des données : passage du format brut (`VARCHAR`) à des types de données propres :

* **Typage** : Conversion en `INT`, `DATE` et `NUMBER`.
* **Parsing dynamique** : Les formats de dates diffèrent selon les villes (Paris, Tokyo, NY). Le format correct est récupéré via une jointure sur le seed `dim_boutiques`.
* **Traductions & Devises** : Utilisation de `LEFT JOIN` sur les seeds pour traduire les produits en français et convertir les montants (USD/JPY) en EUR.

### Couche Gold (`fact_ventes_mensuelles`, `top_produits`)

Implémentation de deux KPIs :

* Calcul du CA mensuel par boutique (`GROUP BY`).
* Classement de la performance produit via des fonctions de fenêtrage (`RANK() OVER`).

## Qualité des données (Tests)

Pour garantir la fiabilité du pipeline, j'ai mis en place deux types de tests :

1. **Tests génériques** (`schema.yml`) : Vérification de l'absence de `NULL` et validation des valeurs acceptées (ex: uniquement EUR, USD ou JPY pour la devise). 
2. **Tests singuliers** (`tests/`) :
* `assert_montants_positifs` : Vérifie qu'aucune ligne n'affiche de CA négatif.
* `assert_dates_coherentes` : S'assure que la date dans la donnée correspond bien au mois indiqué dans le nom du fichier source (évite les inversions jour/mois).



## Commandes principales

Toutes les commandes sont lancées depuis le dossier `retail_transformation/` :

* `dbt seed` : Charge les référentiels CSV dans Snowflake.
* `dbt run` : Exécute l'ensemble des transformations SQL.
* `dbt test` : Vérifie l'intégrité des données.
* `dbt docs generate` : Met à jour la documentation et le graphe de dépendance.
