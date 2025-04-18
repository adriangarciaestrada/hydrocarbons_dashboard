from airflow import DAG
from airflow.providers.google.cloud.transfers.gcs_to_bigquery import GCSToBigQueryOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import timedelta
import pendulum
import os

BUCKET_NAME = "your_bucket_name" #Change with your GCS bucket name
GCS_PREFIX = "your_prefix" #Change with a prefix of your choice
BQ_DATASET = "your_dataset" #Change with your BigQuery dataset
GCP_PROJECT_ID = "your_project_ID" #Change with your GCP project ID
CSV_FOLDER = "/opt/airflow/data/processed_csv"

default_args = {
    "owner": "airflow",
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
}

with DAG(
    dag_id="load_gcs_to_bigquery_dag",
    schedule_interval=None,
    start_date=pendulum.now().subtract(days=1),
    catchup=False,
    default_args=default_args,
    tags=["etl"],
) as dag:

    csv_files = [f for f in os.listdir(CSV_FOLDER) if f.endswith(".csv")]

    tasks = []
    for csv_file in csv_files:
        table_name = csv_file.replace(".csv", "").lower().replace(" ", "_")
        sanitized_gcs_uri = f"gs://{BUCKET_NAME}/{GCS_PREFIX}/{table_name}.csv"

        task = GCSToBigQueryOperator(
            task_id=f"load_{table_name}_to_bq",
            bucket=BUCKET_NAME,
            source_objects=[f"{GCS_PREFIX}/{table_name}.csv"],
            destination_project_dataset_table=f"{GCP_PROJECT_ID}.{BQ_DATASET}.{table_name}",
            source_format="CSV",
            skip_leading_rows=1,
            field_delimiter=",",
            autodetect=True,
            write_disposition="WRITE_TRUNCATE",
            allow_quoted_newlines=True,
            gcp_conn_id="google_cloud_default",
        )

        tasks.append(task)

    trigger_dbt = TriggerDagRunOperator(
        task_id="trigger_dbt_models",
        trigger_dag_id="run_dbt_models_dag"
    )

    tasks >> trigger_dbt
