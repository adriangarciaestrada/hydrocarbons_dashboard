from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import timedelta
import pendulum

with DAG(
    dag_id="run_dbt_models_dag",
    start_date=pendulum.now().subtract(days=1),
    schedule_interval=None,  
    catchup=False,
    default_args={"owner": "airflow"},
    tags=["dbt", "transform"],
) as dag:

    run_dbt = BashOperator(
        task_id="run_dbt_transformations",
        bash_command="cd /opt/airflow/dbt && dbt run"
    )
