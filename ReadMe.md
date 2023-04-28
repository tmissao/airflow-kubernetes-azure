# Airflow Kubernetes Demo
---

This repository aims to create an Airflow environment on a Kubernetes cluster, following the best practices.


## Create a Fernet Key
```python
python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"
```

## Create WebServer Key
```python
python3 -c 'import secrets; print(secrets.token_hex(16))'
```

## Installing
```bash
helm repo add apache-airflow https://airflow.apache.org
helm upgrade --install airflow apache-airflow/airflow --namespace airflow
```

az account set --subscription 33d7eadb-fb41-4ef5-9c37-0d67c95a1e70
az aks get-credentials --resource-group poc-airflow-kubernetes-rg --name poc-airflow-aks