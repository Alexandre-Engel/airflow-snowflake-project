# Airflow

Airflow me sert à coordonner toutes les étapes du projet, de la détection des fichiers locaux jusqu'au déclenchement des transformations dbt.

## Architecture du DAG (`01_ingest_sales_data`)

J'utilise la **TaskFlow API** d'Airflow, ce qui permet d'écrire le workflow de manière plus "Pythonique" avec des décorateurs `@dag` et `@task`. Le pipeline suit un enchaînement linéaire pour garantir l'intégrité des données.

### Étapes du workflow :

1. **`get_files_to_process`** : Scanne le dossier `data/inbox/` pour lister les nouveaux fichiers CSV.
2. **`upload_to_stage`** : Utilise le `SnowflakeHook` pour envoyer les fichiers vers le Stage Snowflake via une commande `PUT`.
3. **`load_into_table`** : Exécute le `COPY INTO` pour charger les données dans la table `RAW`. Je récupère au passage `METADATA$FILENAME` pour tracer l'origine de chaque ligne (indispensable pour que dbt identifie la boutique).
4. **`archive_files`** : Déplace les fichiers traités de `inbox/` vers `archive/` en ajoutant un timestamp pour éviter les doublons.
5. **`cleanup_stage`** : Nettoie le Stage Snowflake (commande `REMOVE`) pour ne pas charger deux fois les mêmes données.
6. **`dbt_run_transformation`** : Utilise un `BashOperator` pour lancer la suite de commandes dbt (`seed`, `run`, `test`).

## Gestion des dépendances

Le chaînage est défini pour s'arrêter immédiatement en cas d'erreur à n'importe quelle étape :

```python
files = get_files_to_process()
uploaded = upload_to_stage(files)
loaded = load_into_table(uploaded)
archived = archive_files(uploaded)
cleaned = cleanup_stage(archived)

cleaned >> dbt_run_transformation

```

## Pourquoi ce choix technique ?

* **Traçabilité** : L'utilisation de `METADATA$FILENAME` permet à la couche Silver de dbt d'appliquer les bons taux de change et formats de date selon la provenance du fichier (Paris, Tokyo ou NY).
* **Modularité** : Chaque étape est isolée. Si l'upload échoue, le fichier reste dans `inbox/` et rien n'est chargé en base.
* **Logs** : L'interface web d'Airflow me permet de consulter les logs détaillés de dbt ou de Snowflake directement en cas de rejet d'une ligne (erreur de format CSV par exemple).
