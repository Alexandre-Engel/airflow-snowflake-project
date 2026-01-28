# Data Ingestion Guide

This document explains how the sales data ingestion pipeline works.

## Overview

The pipeline automatically processes CSV files dropped in the `data/inbox/` folder and loads them into Snowflake.

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│   inbox/    │ ──▶ │  Snowflake  │ ──▶ │  Snowflake  │ ──▶ │  archive/   │
│  CSV files  │     │    Stage    │     │    Table    │     │  Processed  │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
```

## How to Use

### 1. Prepare Your CSV File

Your CSV must have these columns (in order):

| Column | Type | Example |
|--------|------|---------|
| ID_Vente | Integer | 1001 |
| Date_Vente | Date (YYYY-MM-DD) | 2024-01-15 |
| Nom_Produit | Text | T-Shirt Cotton |
| Catégorie | Text | Vêtements |
| Prix_Unitaire | Decimal | 25.00 |
| Quantité | Integer | 2 |
| Montant_Total | Decimal | 50.00 |

Example:
```csv
ID_Vente,Date_Vente,Nom_Produit,Catégorie,Prix_Unitaire,Quantité,Montant_Total
1001,2024-01-15,T-Shirt Cotton Bio,Vêtements,25.00,2,50.00
1002,2024-01-15,Jean Slim Blue,Vêtements,85.50,1,85.50
```

### 2. Drop File in Inbox

Copy your CSV file to `data/inbox/`:

```bash
cp my_sales_data.csv data/inbox/
```

### 3. Trigger the DAG

In Airflow UI:
1. Go to DAGs
2. Find `01_ingest_sales_data`
3. Click the play button (▶) to trigger

Or via CLI:
```bash
airflow dags trigger 01_ingest_sales_data
```

### 4. Check Results

After completion:
- Your file is moved to `data/archive/` with a timestamp
- Data is available in `RETAIL_DB.RAW.SALESDATA_INBOUND`

```sql
SELECT * FROM RETAIL_DB.RAW.SALESDATA_INBOUND 
ORDER BY LOAD_TIMESTAMP DESC;
```

## Pipeline Steps

The DAG executes 5 tasks in sequence:

| Step | Task | Description |
|------|------|-------------|
| 1 | `get_files_to_process` | Scans `inbox/` for CSV files |
| 2 | `upload_to_stage` | Uploads files to Snowflake internal stage |
| 3 | `load_into_table` | Copies data from stage to table |
| 4 | `archive_files` | Moves processed files to `archive/` |
| 5 | `cleanup_stage` | Removes files from Snowflake stage |

## File Lifecycle

```
1. New file arrives:     data/inbox/sales_january.csv
2. After processing:     data/archive/sales_january_20240128_143052.csv
```

Files are renamed with a timestamp to:
- Prevent overwriting previous files
- Track when each file was processed
- Allow reprocessing by copying back to inbox

## Troubleshooting

### No files processed

Check that:
- Files have `.csv` extension
- Files are in `data/inbox/` (not a subdirectory)
- DAG was triggered after files were added

### Connection error

1. Test connection with `00_test_snowflake_connection` DAG
2. Verify credentials in Airflow UI (Admin → Connections)

### Data not appearing in table

Check Airflow task logs for errors:
1. Go to DAG runs
2. Click on the failed task
3. View logs

Common issues:
- CSV column mismatch
- Invalid date format
- Special characters in data

## Reprocessing a File

To reprocess an archived file:

```bash
cp data/archive/sales_january_20240128_143052.csv data/inbox/sales_january.csv
airflow dags trigger 01_ingest_sales_data
```

## Multiple Files

The pipeline processes **all** CSV files in inbox at once. You can drop multiple files before triggering:

```bash
cp january_sales.csv february_sales.csv march_sales.csv data/inbox/
airflow dags trigger 01_ingest_sales_data
```

All files will be uploaded, loaded, and archived in a single run.
