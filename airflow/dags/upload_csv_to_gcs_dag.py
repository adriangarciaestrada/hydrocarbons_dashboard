from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import datetime, timedelta
from google.cloud import storage
import os

def upload_files_to_gcs(bucket_name, local_folder, gcs_prefix):
    client = storage.Client()  # This uses GOOGLE_APPLICATION_CREDENTIALS
    bucket = client.bucket(bucket_name)

    for filename in os.listdir(local_folder):
        if filename.endswith(".csv"):
            local_path = os.path.join(local_folder, filename)
            remote_path = f"{gcs_prefix}/{filename}"

            blob = bucket.blob(remote_path)
            blob.upload_from_filename(local_path)

            print(f"Uploaded {local_path} to gs://{bucket_name}/{remote_path}")

with DAG(
    dag_id="upload_csv_to_gcs_dag",
    start_date=datetime.now() - timedelta(days=1),
    schedule_interval=None,
    catchup=False,
    tags=["etl", "gcs"],
    default_args={"owner": "airflow"},
) as dag:

    upload_task = PythonOperator(
        task_id="upload_csvs",
        python_callable=upload_files_to_gcs,
        op_kwargs={
            "bucket_name": "hydrocarbons-cnhdata-jage-bucket",
            "local_folder": "/opt/airflow/data/processed_csv",
            "gcs_prefix": "hydrocarbons"
        },
    )

    trigger_bq_dag = TriggerDagRunOperator(
        task_id="trigger_load_to_bigquery",
        trigger_dag_id="load_gcs_to_bigquery_dag",  # 🧩 must match the downstream DAG's `dag_id`
        wait_for_completion=False,
        reset_dag_run=True,
    )

    upload_task >> trigger_bq_dag
