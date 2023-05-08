import pathlib
import logging
from airflow import DAG
from airflow.models import Variable
from datetime import datetime, timedelta
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.azure.transfers.local_to_wasb import LocalFilesystemToWasbOperator

# Set Azure Log Level to avoid noise
logger = logging.getLogger('azure')
logger.setLevel(logging.WARNING)

default_args = {
    'start_date': datetime(2023, 1, 26),
    'owner': 'Airflow',
    'email': 'owner@test.com',
    'retries': 3,
    'retry_delay': timedelta(seconds=30),
}


def write_file(templates_dict):
    filepath = f'{pathlib.Path().resolve()}/{templates_dict["filename"]}'
    secret = templates_dict["secret"]
    print(f'writing file {filepath}')
    with open(filepath, "w") as file:
        file.write(f"This is my demo file!\nThe secret is: {secret}\n")
    return filepath


with DAG(
  dag_id='secrets_test', 
  schedule_interval="*/60 * * * *", 
  default_args=default_args,
  catchup=False
) as dag:
    
    task2 = PythonOperator(
        task_id='write_file', 
        python_callable=write_file,
        templates_dict = {
            'filename' : "{{ ts }}.txt",
            'secret' : '{{var.value.get("my-secret")}}'
        }
    )

    task3 = LocalFilesystemToWasbOperator(
        task_id='send_to_blob',
        wasb_conn_id='azure-storage',
        file_path='{{ ti.xcom_pull(task_ids=["write_file"])[0] }}',
        container_name='upload',
        create_container=True,
        blob_name='{{ ts_nodash }}'
    )

    task2 >> task3
