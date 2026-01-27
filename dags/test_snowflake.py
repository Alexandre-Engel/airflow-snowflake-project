"""
Test Snowflake DAG
This DAG demonstrates basic Snowflake integration with Apache Airflow
"""
from datetime import datetime, timedelta
from airflow import DAG
from airflow.providers.snowflake.operators.snowflake import SnowflakeOperator

# Default arguments for the DAG
default_args = {
    'owner': 'airflow',
    'depends_on_past': False,
    'start_date': datetime(2024, 1, 1),
    'email_on_failure': False,
    'email_on_retry': False,
    'retries': 1,
    'retry_delay': timedelta(minutes=5),
}

# Define the DAG
dag = DAG(
    'test_snowflake',
    default_args=default_args,
    description='A simple DAG to test Snowflake connection',
    schedule_interval=timedelta(days=1),
    catchup=False,
    tags=['test', 'snowflake'],
)

# Test Snowflake connection with a simple query
test_query = SnowflakeOperator(
    task_id='test_snowflake_connection',
    snowflake_conn_id='snowflake_default',
    sql='SELECT CURRENT_VERSION();',
    dag=dag,
)

# Create a test table
create_table = SnowflakeOperator(
    task_id='create_test_table',
    snowflake_conn_id='snowflake_default',
    sql="""
        CREATE TABLE IF NOT EXISTS test_table (
            id INTEGER,
            name VARCHAR(100),
            created_at TIMESTAMP_NTZ DEFAULT CURRENT_TIMESTAMP()
        );
    """,
    dag=dag,
)

# Insert test data
insert_data = SnowflakeOperator(
    task_id='insert_test_data',
    snowflake_conn_id='snowflake_default',
    sql="""
        INSERT INTO test_table (id, name)
        VALUES 
            (1, 'Test Record 1'),
            (2, 'Test Record 2'),
            (3, 'Test Record 3');
    """,
    dag=dag,
)

# Query test data
query_data = SnowflakeOperator(
    task_id='query_test_data',
    snowflake_conn_id='snowflake_default',
    sql='SELECT * FROM test_table;',
    dag=dag,
)

# Set task dependencies
test_query >> create_table >> insert_data >> query_data
