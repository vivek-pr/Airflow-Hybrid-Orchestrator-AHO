import os
from datetime import datetime

import requests
from airflow import DAG
from airflow.operators.python import PythonOperator

WORKER_URL = os.environ.get("WORKER_URL", "http://host.minikube.internal:5000/run-task")

def trigger_external_worker():
    """Send a POST request to the external worker service."""
    response = requests.post(WORKER_URL, timeout=10)
    response.raise_for_status()

with DAG(
    dag_id="external_trigger_dag",
    start_date=datetime(2023, 1, 1),
    schedule=None,
    catchup=False,
    tags=["example", "external"],
) as dag:
    PythonOperator(
        task_id="invoke_worker",
        python_callable=trigger_external_worker,
    )
