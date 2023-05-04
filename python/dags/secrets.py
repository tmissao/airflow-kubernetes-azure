import pathlib
from airflow import DAG
from airflow.models import Variable
from datetime import datetime, timedelta
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.azure.transfers.local_to_wasb import LocalFilesystemToWasbOperator

default_args = {
    'start_date': datetime(2023, 1, 26),
    'owner': 'Airflow',
    'email': 'owner@test.com',
    'retries': 3,
    'retry_delay': timedelta(seconds=30),
}

# def get_secrets(**kwargs):
#     print(f'value var_name is {kwargs["var_name"]}')
#     variable = Variable.get(kwargs["var_name"])
#     print(f'the value of the secret is: ${variable}')
#     for x in variable:
#         print(f'secret: {x}')
#     return variable


def write_file(templates_dict):
    content = templates_dict["content"]
    print(f'the content is: {content}')
    filepath = f'{pathlib.Path().resolve()}/{templates_dict["filename"]}'
    print(f'writing file {file}')
    with open(filepath, "w") as file:
        file.write(f"This is my demo file!\nThe secret is {content[0]}\n")
    return filepath


with DAG(
  dag_id='secrets-test', 
  schedule_interval="*/60 * * * *", 
  default_args=default_args,
  catchup=False
) as dag:
    
    # task = PythonOperator(
    #     task_id='get_secret', 
    #     python_callable=get_secrets,
    #     op_kwargs = {
    #         'var_name' : 'my-secret'
    #     }
    # )

    task2 = PythonOperator(
        task_id='write_file', 
        python_callable=write_file,
        templates_dict = {
            'filename' : "{{ ts }}.txt",
            'content' : "{{var.value.my-secret}}"
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
