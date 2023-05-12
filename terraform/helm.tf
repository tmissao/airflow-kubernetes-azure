
resource "kubernetes_namespace" "nginx" {
  metadata {
    name = "nginx"
  }
}

resource "kubernetes_namespace" "airflow" {
  metadata {
    name = "airflow"
  }
}

resource "helm_release" "nginx" {
  name       = "nginx"
  repository = "https://kubernetes.github.io/ingress-nginx"
  chart      = "ingress-nginx"
  namespace  = one(kubernetes_namespace.nginx.metadata).name
  values = [
    templatefile("../helm/nginx/values.tftpl", {
      LOADBALANCE_IP      = azurerm_public_ip.this.ip_address
      RESOURCE_GROUP_NAME = azurerm_resource_group.this.name
    })
  ]
  depends_on = [
    azurerm_kubernetes_cluster.this,
    azurerm_public_ip.this,
    azurerm_role_assignment.network_aks_contributor_rg
  ]
}

resource "helm_release" "airflow" {
  name       = var.airflow.chart_name
  repository = "https://airflow.apache.org"
  chart      = "airflow"
  namespace  = one(kubernetes_namespace.airflow.metadata).name
  version    = var.airflow.chart_version
  values = [
    templatefile("../helm/airflow/values.tftpl", {
      AIRFLOW_IMAGE_REPOSITORY                     = "${azurerm_container_registry.this.name}.azurecr.io/${var.airflow_custom_image.acr_image_path}"
      AIRFLOW_IMAGE_TAG                            = "latest"
      AIRFLOW_FERNET_KEY                           = var.airflow.fernet_key
      AIRFLOW_WEBSERVER_SECRET_KEY                 = var.airflow.webserver_secret_key
      AIRFLOW_DEFAULT_USER_USERNAME                = var.airflow.default_user.username
      AIRFLOW_DEFAULT_USER_PASSWORD                = var.airflow.default_user.password
      POSTGRES_USER                                = azurerm_postgresql_flexible_server.this.administrator_login
      POSTGRES_PASSWORD                            = nonsensitive(azurerm_postgresql_flexible_server.this.administrator_password)
      POSTGRES_HOST                                = azurerm_postgresql_flexible_server.this.fqdn
      POSTGRES_DATABASE                            = azurerm_postgresql_flexible_server_database.this.name
      REDIS_HOST                                   = azurerm_redis_cache.this.hostname
      REDIS_PORT                                   = azurerm_redis_cache.this.ssl_port
      REDIS_PASSWORD                               = nonsensitive(azurerm_redis_cache.this.primary_access_key)
      AZURE_STORAGE_ACCOUNT_LOGS_CONNECTION_STRING = base64encode("wasb://${azurerm_storage_account.this.name}:${urlencode(nonsensitive(azurerm_storage_account.this.primary_access_key))}")
      AIRFLOW_LOG_STORAGE_ACCOUNT                  = azurerm_storage_account.this.name
      AIRFLOW_LOG_CONTAINER                        = azurerm_storage_container.this.name
      AZURE_KEYVAULT_URI                           = azurerm_key_vault.this.vault_uri
      AZURE_TENANT_ID                              = data.azurerm_client_config.current.tenant_id
      AZURE_CLIENT_ID                              = azuread_application.this.application_id
      AZURE_CLIENT_SECRET                          = base64encode(nonsensitive(azuread_application_password.this.value))
      KEYVAULT_CONNECTIONS_PREFIX                  = var.airflow.keyvault_connections_prefix
      KEYVAULT_VARIABLES_PREFIX                    = var.airflow.keyvault_variables_prefix
      AIRFLOW_DAG_GITSYNC_REPO                     = var.airflow.dag_repository.repo
      AIRFLOW_DAG_GITSYNC_BRANCH                   = var.airflow.dag_repository.branch
      AIRFLOW_DAG_GITSYNC_SUBPATH                  = var.airflow.dag_repository.subPath
    })
  ]
  depends_on = [
    azurerm_kubernetes_cluster.this,
    helm_release.nginx,
    azurerm_role_assignment.allow_aks_to_pull,
    null_resource.build_airflow_docker_image
  ]
}