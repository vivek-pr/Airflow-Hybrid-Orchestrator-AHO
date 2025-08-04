from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    'poc_test',
    start_date=datetime(2025, 8, 1),
    schedule=None,
    max_active_tasks=2,
) as dag:
    echo = BashOperator(task_id='echo', bash_command='echo "Hello from Airflow"')
    sleep = BashOperator(task_id='sleep', bash_command='sleep 5')
    echo >> sleep
