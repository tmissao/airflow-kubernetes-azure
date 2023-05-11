# Airflow on Kubernetes 
---

This project aims to create a production ready Airflow environment in Kubernetes Cluster at Azure Cloud Provider, using Terraform in order to provision the underlying resources and Helm Charts to install applications in Kubernetes.

The Goals of this project are:

1. Install Airflow in Kubernetes using [Helm Official Chart](https://airflow.apache.org/docs/helm-chart/stable/index.html).
2. Configure an external Database ([Postgres](https://www.postgresql.org/)) for the Airflow Metastore using SSL.
3. Configure Connection Pool ([PgBouncer](https://www.pgbouncer.org/2023/05/pgbouncer-1-19-0)) in order reduce the number of open connections.
4. Configure an external Redis Cluster to be used as [Celery Backend](https://docs.celeryq.dev/en/stable/getting-started/backends-and-brokers/redis.html).
5. Configure Airflow [CeleryKubernetes Executor](https://airflow.apache.org/docs/apache-airflow/stable/core-concepts/executor/celery_kubernetes.html).
6. Mounting DAGs from a Git Repository using [Git-Sync SideCar](https://airflow.apache.org/docs/helm-chart/stable/manage-dags-files.html#mounting-dags-using-git-sync-sidecar-without-persistence).
7. Include External Airflow Providers ([Microsoft Azure](https://airflow.apache.org/docs/apache-airflow-providers-microsoft-azure/stable/index.html)) on Airflow Image.
8. Configure Airflow Task Logging to use [Azure Blob Storage](https://airflow.apache.org/docs/apache-airflow-providers-microsoft-azure/stable/logging/index.html).
9. Configure Airflow to use Azure Key Vault as [Secret Backend](https://airflow.apache.org/docs/apache-airflow-providers-microsoft-azure/stable/secrets-backends/azure-key-vault.html).
10. Configure and expose Airflow UI using [Nginx Ingress](https://docs.nginx.com/nginx-ingress-controller/installation/installation-with-helm/).
11. Monitore Celery Executor using [Flower](https://flower.readthedocs.io/en/latest/).
12. Include/Run Maintenance DAGs.


## Setup
---

- [Create an Azure Account](https://azure.microsoft.com/en-us/free/)
- [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Install TF_ENV](https://github.com/tfutils/tfenv)
- [Install Python 3.7](https://www.linuxcapable.com/how-to-install-python-3-7-on-ubuntu-20-04-lts/)
- [Install Docker](https://docs.docker.com/engine/install/ubuntu/)

## Provisioning Infrastructure
---
First of all, generate a brand new [Fernet Key](https://airflow.apache.org/docs/apache-airflow/stable/administration-and-deployment/security/secrets/fernet.html) (used to encrypt passwords in the connection configuration and variable configuration), and [WebServer Secret Key](https://airflow.apache.org/docs/helm-chart/stable/production-guide.html#webserver-secret-key) (used to sign session cookies and perform security related functions).

### Generate Fernet Key
---
```bash
python -c "from cryptography.fernet import Fernet; FERNET_KEY = Fernet.generate_key().decode(); print(FERNET_KEY)"
```

Place the generated value under the variable `airflow.fernet_key` at [terraform variables file](./terraform/variables.tf)

### Generate WebServer Secret Key
---
```bash
python -c 'import secrets; print(secrets.token_hex(16))'
```

Place the generated value under the variable `airflow.webserver_secret_key` at [terraform variables file](./terraform/variables.tf)

### Execute Terraform
--- 

This environment is totally build using [Terraform](https://www.terraform.io/)

```bash
# from repository root folder
cd infrastructure
az login
tfenv install
tfenv use
terraform init
terraform apply
```

## Outputs
---

After execute the command above, go to your web browser and access the public ip specified under the output `airflow.webserver.host` and login in your brand new Airflow!

```bash

airflow = {
  "webserver" = {
    "host" = "20.112.89.18" # <-- Airflow UI Address
    "login" = {
      "password" = "admin"  # <-- Airflow Login Password
      "username" = "admin"  # <-- Airflow Login Username
    }
  }
}

kubernetes = {
  "fqnd" = "poc-airflow-aks-9ftxhpwd.hcp.westus2.azmk8s.io"
  "nginx_ingress_public_ip" = "20.112.89.18"
}

postgres = {
  "administrator_login" = "adminpsql"
  "administrator_password" = "dATZS1fyPwo34x7Q"
  "host" = "poc-airflow-database.postgres.database.azure.com" 
}

redis = {
  "host" = "poc-airflow-redis.redis.cache.windows.net"
  "primary_access_key" = "NdK9GbwXFXT7uDlg1UtSzHCeD4HEYnniTAzCaN7iad8="
  "primary_connection_string" = "poc-airflow-redis.redis.cache.windows.net:6380,password=NdK9GbwXFXT7uDlg1UtSzHCeD4HEYnniTAzCaN7iad8=,ssl=true,abortConnect=False"
  "ssl_port" = 6380
}
```

## Results
---