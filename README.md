# Airflow Snowflake Project

Pipeline de données avec Apache Airflow 3 et Snowflake.

## Prérequis

- Python 3.11+
- Compte Snowflake

## Installation

```bash
# Créer l'environnement virtuel
python -m venv venv
source venv/bin/activate

# Installer les dépendances
pip install -r requirements.txt

# Initialiser Airflow
export AIRFLOW_HOME=$(pwd)
airflow db init
airflow users create \
    --username admin \
    --firstname Admin \
    --lastname User \
    --role Admin \
    --email admin@example.com \
    --password admin
```

## Configuration Snowflake

Configurer la connexion `snowflake_conn_id` dans l'UI Airflow :
- **Conn Type**: Snowflake
- **Account**: votre_compte.region
- **Login**: votre_user
- **Password**: votre_password
- **Schema**: votre_schema
- **Database**: votre_database
- **Warehouse**: votre_warehouse

## Démarrage

```bash
./start_airflow.sh
```

Interface disponible sur http://localhost:8080

## Structure

```
├── dags/                    # DAGs Airflow
├── .devcontainer/           # Configuration Dev Container
├── requirements.txt         # Dépendances Python
└── start_airflow.sh         # Script de démarrage
```

## DAGs

| DAG | Description |
|-----|-------------|
| `00_test_snowflake_connection` | Test de connexion Snowflake |
