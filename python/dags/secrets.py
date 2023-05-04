import pendulum
from airflow import DAG
from airflow.models import Variable
from datetime import datetime, timedelta
from airflow.operators.python import PythonOperator
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
    filename = kwargs["filename"]
    content = kwargs['ti'].xcom_pull(task_ids=['get_secret'])
    print(f'writing file {pathlib.Path().resolve()}/{filename}')
    f = open(filename, "w")
    f.write(f"This is my demo file!\n The secret is {content[0]}")
    f.close()


with DAG(
  dag_id='secrets-test', 
  schedule_interval="*/60 * * * *", 
  default_args=default_args,
  catchup=False
) as dag:
    
    python_task = PythonOperator(
        task_id='get_secret', 
        python_callable=get_secrets,
        op_kwargs = {
            'var_name' : 'my-secret'
        }
    )

    python_task2 = PythonOperator(
        task_id='write_file', 
        python_callable=write_file,
        op_kwargs = {
            'filename' : 'demo.txt'
        }
    )

    python_task >> python_task2
