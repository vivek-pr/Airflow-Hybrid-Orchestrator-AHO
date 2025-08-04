from airflow import DAG
from airflow.operators.bash import BashOperator
from datetime import datetime

with DAG(
    'poc_test',
    start_date=datetime(2025, 8, 1),
    schedule=None,
    max_active_tasks=2,
) as dag:
    t1 = BashOperator(task_id='echo_hello', bash_command='echo "Hello from pod!"')
    t2 = BashOperator(task_id='sleep', bash_command='sleep 5')
    t3 = BashOperator(task_id='echo_world', bash_command='echo "World"')
    t1 >> t2 >> t3
