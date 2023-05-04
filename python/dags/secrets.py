import pendulum
from airflow import DAG
from airflow.models import Variable
from datetime import datetime, timedelta
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.azure.transfers.local_to_wasb import LocalFilesystemToWasbOperator
import pathlib

default_args = {
    'start_date': datetime(2023, 1, 26),
    'owner': 'Airflow',
    'email': 'owner@test.com',
    'retries': 3,
    'retry_delay': timedelta(seconds=30),
}

def get_secrets(**kwargs):
    print(f'value var_name is {kwargs["var_name"]}')
    variable = Variable.get(kwargs["var_name"])
    print(f'the value of the secret is: ${variable}')
    for x in variable:
        print(f'secret: {x}')
    return variable


def write_file(**kwargs):
    print(f'kwargs: ${kwargs}')
    filename = kwargs["filename"]
    content = kwargs['ti'].xcom_pull(task_ids=['get_secret'])
    print(f'writing file generated {kwargs["templates_dict"]["filename"]}')
    print(f'writing file {pathlib.Path().resolve()}/{filename}')
    f = open(filename, "w")
    f.write(f"This is my demo file!\nThe secret is {content[0]} .\n")
    f.close()


with DAG(
  dag_id='secrets-test', 
  schedule_interval="*/60 * * * *", 
  default_args=default_args,
  catchup=False
) as dag:
    
    task = PythonOperator(
        task_id='get_secret', 
        python_callable=get_secrets,
        op_kwargs = {
            'var_name' : 'my-secret'
        }
    )

    task2 = PythonOperator(
        task_id='write_file', 
        python_callable=write_file,
        op_kwargs = {
            'filename' : 'demo.txt'
        },
        templates_dict = {
            'filename' : "{{ ts }}.txt"
        }
    )

    task3 = LocalFilesystemToWasbOperator(
        task_id='send_to_blob',
        wasb_conn_id='azure-storage',
        file_path='/opt/airflow/demo.txt',
        container_name='upload',
        create_container=True,
        blob_name='demo.txt'
    )

    task >> task2 >> task3
