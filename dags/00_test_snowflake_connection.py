from airflow.decorators import dag, task
from datetime import datetime

# Définition du DAG avec le décorateur (Style Airflow 2/3 moderne)
@dag(
    dag_id='00_test_snowflake_connection',
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['test', 'snowflake']
)
def check_connection():

    @task
    def ping_snowflake_db():
        """Test de connexion Snowflake avec le hook directement"""
        from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook
        
        # Utilise la connexion configurée dans Airflow
        hook = SnowflakeHook(snowflake_conn_id='snowflake_conn_id')
        
        # Exécute une requête simple
        result = hook.get_first(
            "SELECT CURRENT_VERSION(), CURRENT_ROLE(), CURRENT_DATABASE();"
        )
        
        print(f"✅ Connexion Snowflake OK!")
        print(f"   Version: {result[0]}")
        print(f"   Rôle: {result[1]}")
        print(f"   Base: {result[2]}")
        
        return {"version": result[0], "role": result[1], "database": result[2]}

    # Exécute la tâche
    ping_snowflake_db()

# On instancie le DAG
check_connection()