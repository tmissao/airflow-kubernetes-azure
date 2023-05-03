import pendulum
from airflow import DAG
from datetime import datetime, timedelta
from airflow.operators.python import PythonOperator
from airflow.providers.microsoft.azure.secrets.key_vault import AzureKeyVaultBackend

default_args = {
    'start_date': datetime(2023, 1, 26),
    'owner': 'Airflow',
    'email': 'owner@test.com',
    'retries': 3,
    'retry_delay': timedelta(seconds=30),
}

def get_secrets(**kwargs):
    print(f'value var_name is {kwargs["var_name"]}')
    print(f'value from kwargs is {kwargs}')
    variable = AzureKeyVaultBackend.get_variable(key = kwargs["var_name"])
    print(variable)

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
