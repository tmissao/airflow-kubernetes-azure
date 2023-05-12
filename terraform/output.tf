output "postgres" {
  value = {
    host                   = azurerm_postgresql_flexible_server.this.fqdn
    administrator_login    = azurerm_postgresql_flexible_server.this.administrator_login
    administrator_password = nonsensitive(azurerm_postgresql_flexible_server.this.administrator_password)
  }
}

output "redis" {
  value = {
    host                      = azurerm_redis_cache.this.hostname
    ssl_port                  = azurerm_redis_cache.this.ssl_port
    primary_access_key        = nonsensitive(azurerm_redis_cache.this.primary_access_key)
    primary_connection_string = nonsensitive(azurerm_redis_cache.this.primary_connection_string)
  }
}

output "kubernetes" {
  value = {
    fqnd                    = azurerm_kubernetes_cluster.this.fqdn
    nginx_ingress_public_ip = azurerm_public_ip.this.ip_address
  }
}

output "airflow" {
  value = {
    webserver = {
      host = azurerm_public_ip.this.ip_address
      login = {
        username = var.airflow.default_user.username
        password = var.airflow.default_user.password
      }
    }
  }
}