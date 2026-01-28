"""
Sales Data Ingestion Pipeline
Loads CSV files from inbox folder to Snowflake, then archives them.
"""

from airflow.decorators import dag, task
from datetime import datetime
from pathlib import Path
import os
import shutil
import certifi


AIRFLOW_HOME = Path(os.environ.get("AIRFLOW_HOME", "/workspaces/airflow-snowflake-project"))
INBOX_PATH = AIRFLOW_HOME / "data" / "inbox"
ARCHIVE_PATH = AIRFLOW_HOME / "data" / "archive"
SNOWFLAKE_CONN_ID = "snowflake_conn_id"
STAGE_PATH = "@RETAIL_DB.RAW.SF_STAGE_SALES"


@dag(
    dag_id="01_ingest_sales_data",
    schedule=None,
    start_date=datetime(2024, 1, 1),
    catchup=False,
    tags=["elt", "snowflake", "sales"],
)
def sales_ingestion_pipeline():
    """
    Pipeline d'ingestion des données de ventes.
    
    Workflow:
        1. Scan du dossier inbox pour les fichiers CSV
        2. Upload vers le Stage Snowflake
        3. Chargement dans la table RAW
        4. Archivage des fichiers traités
    """

    @task
    def get_files_to_process() -> list[str]:
        """Récupère la liste des fichiers CSV présents dans inbox."""
        if not INBOX_PATH.exists():
            INBOX_PATH.mkdir(parents=True, exist_ok=True)
            return []

        csv_files = list(INBOX_PATH.glob("*.csv"))
        
        if not csv_files:
            print("📭 Aucun fichier à traiter dans inbox/")
            return []
        
        file_paths = [str(f) for f in csv_files]
        print(f"📬 {len(file_paths)} fichier(s) à traiter: {[f.name for f in csv_files]}")
        return file_paths

    @task
    def upload_to_stage(file_paths: list[str]) -> list[str]:
        """Upload les fichiers vers le Stage Snowflake."""
        if not file_paths:
            return []

        from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

        os.environ.setdefault("REQUESTS_CA_BUNDLE", certifi.where())
        os.environ.setdefault("SSL_CERT_FILE", certifi.where())

        hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
        connection = hook.get_conn()
        cursor = connection.cursor()

        uploaded_files = []
        
        for file_path in file_paths:
            file_name = Path(file_path).name
            sql_put = f"PUT file://{file_path} {STAGE_PATH} AUTO_COMPRESS=TRUE OVERWRITE=TRUE"
            
            try:
                cursor.execute(sql_put)
                uploaded_files.append(file_path)
                print(f"✅ Uploadé: {file_name}")
            except Exception as e:
                print(f"❌ Erreur upload {file_name}: {e}")

        cursor.close()
        connection.close()
        
        return uploaded_files

    @task
    def load_into_table(uploaded_files: list[str]) -> int:
        """Charge les données du Stage vers la table Snowflake."""
        if not uploaded_files:
            print("⏭️  Aucun fichier à charger")
            return 0

        from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

        hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)

        sql_copy = """
            COPY INTO RETAIL_DB.RAW.SALESdata_INBOUND
            (ID_SALE, SALE_DATE, PRODUCT_NAME, CATEGORY, UNIT_PRICE, QUANTITY, TOTAL_AMOUNT, SOURCE_FILE_NAME)
            FROM (
                SELECT t.$1, t.$2, t.$3, t.$4, t.$5, t.$6, t.$7, METADATA$FILENAME
                FROM @RETAIL_DB.RAW.SF_STAGE_SALES t
            )
            FILE_FORMAT = (FORMAT_NAME = RETAIL_DB.RAW.MY_CSV_FORMAT)
            PATTERN = '.*\\.csv\\.gz'
            ON_ERROR = 'SKIP_FILE'
        """

        result = hook.run(sql_copy, handler=lambda cur: cur.fetchall())
        rows_loaded = sum(row[3] for row in result) if result else 0
        
        print(f"✅ {rows_loaded} lignes chargées dans SALESdata_INBOUND")
        return rows_loaded

    @task
    def archive_files(uploaded_files: list[str]) -> list[str]:
        """Déplace les fichiers traités vers le dossier archive."""
        if not uploaded_files:
            return []

        ARCHIVE_PATH.mkdir(parents=True, exist_ok=True)
        timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
        archived = []

        for file_path in uploaded_files:
            source = Path(file_path)
            if not source.exists():
                continue

            dest_name = f"{source.stem}_{timestamp}{source.suffix}"
            dest_path = ARCHIVE_PATH / dest_name

            shutil.move(str(source), str(dest_path))
            archived.append(str(dest_path))
            print(f"📦 Archivé: {source.name} → {dest_name}")

        return archived

    @task
    def cleanup_stage(archived_files: list[str]) -> None:
        """Nettoie le Stage Snowflake après chargement."""
        if not archived_files:
            return

        from airflow.providers.snowflake.hooks.snowflake import SnowflakeHook

        hook = SnowflakeHook(snowflake_conn_id=SNOWFLAKE_CONN_ID)
        hook.run(f"REMOVE {STAGE_PATH} PATTERN='.*\\.csv\\.gz'")
        print("🧹 Stage nettoyé")

    # DAG Flow
    files = get_files_to_process()
    uploaded = upload_to_stage(files)
    load_into_table(uploaded)
    archived = archive_files(uploaded)
    cleanup_stage(archived)


sales_ingestion_pipeline()
