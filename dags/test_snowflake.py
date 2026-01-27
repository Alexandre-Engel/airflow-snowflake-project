from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator
from datetime import datetime, timedelta

default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

with DAG(
    'test_snowflake_connection',
    default_args=default_args,
    description='Test de connexion Snowflake',
    schedule_interval=None,  # Manuel uniquement
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=['test', 'snowflake'],
) as dag:

    # Test simple : récupérer la version de Snowflake
    test_connection = SnowflakeOperator(
        task_id='test_version',
        snowflake_conn_id='snowflake_default',
        sql='SELECT CURRENT_VERSION();'
    )

    # Exemple de requête
    query_exemple = SnowflakeOperator(
        task_id='query_exemple',
        snowflake_conn_id='snowflake_default',
        sql='''
            SELECT CURRENT_DATE() as date_jour,
                   CURRENT_USER() as utilisateur,
                   CURRENT_WAREHOUSE() as warehouse;
        '''
    )

    test_connection >> query_exemple
