from airflow import DAG
from airflow.operators.python import PythonOperator
from airflow.operators.trigger_dagrun import TriggerDagRunOperator
from datetime import timedelta
import os
import pandas as pd
import pendulum
import re
from unidecode import unidecode

def sanitize_column_name(col):
    col = unidecode(str(col))                   
    col = re.sub(r"[^\w\s]", "", col)           
    col = col.strip().replace(" ", "_")         
    return col.lower()

def sanitize_dataframe(df):
    df.columns = [sanitize_column_name(col) for col in df.columns]

    for col in df.select_dtypes(include=["object"]).columns:
        df[col] = df[col].astype(str).apply(lambda x: unidecode(x).strip())

    return df

def sanitize_filename(filename):
    name = filename.replace(".xlsx", "")
    name = unidecode(name)                     
    name = re.sub(r"[^\w\s]", "", name)        
    name = name.strip().replace(" ", "_")     
    return name.lower() + ".csv"

def convert_excel_to_csv():
    input_folder = "/opt/airflow/data/raw_excel"
    output_folder = "/opt/airflow/data/processed_csv"

    os.makedirs(output_folder, exist_ok=True)

    for filename in os.listdir(input_folder):
        if filename.endswith(".xlsx"):
            excel_path = os.path.join(input_folder, filename)
            sanitized_csv_name = sanitize_filename(filename)
            csv_path = os.path.join(output_folder, sanitized_csv_name)

            df = pd.read_excel(excel_path)
            df = sanitize_dataframe(df)
            df.to_csv(csv_path, index=False)

with DAG(
    dag_id="convert_excel_to_csv_dag",
    start_date=pendulum.now().subtract(days=1),
    schedule_interval="0 0 1 * *",
    catchup=False,
    tags=["etl"],
    default_args={"owner": "airflow"},
) as dag:

    convert_task = PythonOperator(
        task_id="convert_excel_to_csv",
        python_callable=convert_excel_to_csv,
    )

    trigger_upload = TriggerDagRunOperator(
        task_id="trigger_upload_csv_to_gcs",
        trigger_dag_id="upload_csv_to_gcs_dag",
    )

    convert_task >> trigger_upload
