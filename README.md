# Airflow Snowflake Pipeline

Data pipeline using Apache Airflow 3 and Snowflake for sales data ingestion.

## Architecture

```
data/
├── inbox/      ← Drop CSV files here
└── archive/    ← Processed files moved here automatically
```

## Quick Start

### 1. Prerequisites

- Python 3.11+
- Snowflake account

### 2. Snowflake Setup

Run `snowflake/init.sql` in Snowflake to create:
- Warehouse, database, schemas (Medallion architecture)
- File format and stage for data loading
- Target table for sales data

### 3. Airflow Setup

```bash
# Install dependencies
pip install -r requirements.txt

# Initialize Airflow
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

### 4. Configure Snowflake Connection

In Airflow UI (Admin → Connections), create `snowflake_conn_id`:

| Field | Value |
|-------|-------|
| Conn Type | Snowflake |
| Account | your_account.region |
| Login | your_username |
| Password | your_password |
| Schema | RAW |
| Database | RETAIL_DB |
| Warehouse | RETAIL_WH |
| Role | AIRFLOW_ROLE |

### 5. Run

```bash
./start_airflow.sh
```

Access UI at http://localhost:8080

## DAGs

| DAG | Description |
|-----|-------------|
| `00_test_snowflake_connection` | Validates Snowflake connectivity |
| `01_ingest_sales_data` | Loads CSVs from inbox → Snowflake → archive |

## Data Ingestion

See [docs/INGESTION.md](docs/INGESTION.md) for detailed documentation.

## Project Structure

```
├── dags/                   # Airflow DAG definitions
├── data/
│   ├── inbox/              # CSV files to process
│   └── archive/            # Processed files
├── snowflake/              # SQL setup scripts
├── docs/                   # Documentation
└── .devcontainer/          # Dev container config
```
