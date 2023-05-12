locals {
  tags = merge(
    var.tags,
    {
      subscription   = data.azurerm_subscription.current.display_name,
      resource_group = var.resource_group.name
    }
  )
}

data "azurerm_subscription" "current" {}

data "azurerm_client_config" "current" {}

data "azuread_client_config" "current" {}

variable "resource_group" {
  type = object({
    name     = string,
    location = string
  })
  default = {
    name     = "poc-airflow-kubernetes-rg"
    location = "westus2"
  }
}

variable "virtual_network" {
  type = object({
    name          = string
    address_space = list(string)
    subnet = object({
      name             = string
      address_prefixes = list(string)
    })
  })
  default = {
    name          = "poc-airflow-vnet"
    address_space = ["10.0.0.0/16"]
    subnet = {
      name             = "poc-airflow-aks-snet"
      address_prefixes = ["10.0.1.0/24"]
    }
  }
}

variable "virtual_network_security_rules" {
  type = object({
    name = string
    rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = string
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  })
  default = {
    name = "poc-airflow-nsg"
    rules = [
      {
        name                       = "allow-http"
        priority                   = 1001
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "80"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      },
      {
        name                       = "allow-https"
        priority                   = 1002
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_range     = "443"
        source_address_prefix      = "*"
        destination_address_prefix = "*"
      }
    ]
  }
}

variable "kubernetes" {
  type = object({
    name    = string
    version = string
    default_node_pool = object({
      name                = string
      enable_auto_scaling = bool
      max_count           = number
      node_count          = number
      min_count           = number
      vm_size             = string
      node_labels         = map(string)
    })
    network_profile = object({
      network_plugin     = string
      network_policy     = string
      load_balancer_sku  = string
      service_cidr       = string
      docker_bridge_cidr = string
    })
  })
  default = {
    name    = "poc-airflow-aks"
    version = "1.24"
    default_node_pool = {
      name                = "default"
      enable_auto_scaling = true
      max_count           = 3
      node_count          = 1
      min_count           = 1
      vm_size             = "Standard_B2ms"
      node_labels         = { "node-type" = "system" }
    }
    network_profile = {
      network_plugin     = "azure"
      network_policy     = "azure"
      load_balancer_sku  = "standard"
      service_cidr       = "10.2.0.0/16"
      docker_bridge_cidr = "10.3.0.0/16"
    }
  }
}

variable "postgres" {
  type = object({
    name                = string
    version             = number
    administrator_login = string
    storage_mb          = number
    sku_name            = string
    zone                = number
    allowed_to_connect_ips = map(object({
      start_ip_address = string
      end_ip_address   = string
    }))
  })
  default = {
    name                = "poc-airflow-database"
    version             = 14
    administrator_login = "adminpsql"
    storage_mb          = 32768
    sku_name            = "B_Standard_B1ms"
    zone                = 3
    allowed_to_connect_ips = {
      azure-services = {
        start_ip_address = "0.0.0.0"
        end_ip_address   = "0.0.0.0"
      }
    }
  }
}

variable "acr" {
  type = object({
    name = string
    sku  = string
  })
  default = {
    name = "pocmissaoairflow"
    sku  = "Basic"
  }
}

variable "redis" {
  type = object({
    name                = string
    capacity            = number
    family              = string
    sku_name            = string
    enable_non_ssl_port = bool
    redis_version       = number
    redis_configuration = object({
      enable_authentication = bool
    })
  })
  default = {
    name                = "poc-airflow-redis"
    capacity            = 0
    family              = "C"
    sku_name            = "Basic"
    enable_non_ssl_port = false
    redis_version       = 6
    redis_configuration = {
      enable_authentication = true
    }
  }
}

variable "storage_account" {
  type = object({
    name                     = string
    tier                     = string
    account_replication_type = string
  })
  default = {
    name                     = "pocmissaoairflow"
    tier                     = "Standard"
    account_replication_type = "LRS"
  }
}

variable "keyvault" {
  type = object({
    name                        = string
    sku_name                    = string
    purge_protection_enabled    = bool
    enabled_for_disk_encryption = bool
    soft_delete_retention_days  = number
  })
  default = {
    name                        = "poc-airflow-kv"
    sku_name                    = "standard"
    purge_protection_enabled    = false
    enabled_for_disk_encryption = true
    soft_delete_retention_days  = 7
  }
}

variable "nginx_public_ip" {
  type = object({
    name              = string
    allocation_method = string
    sku               = string
  })
  default = {
    name              = "poc-airflow-nginx-ip"
    allocation_method = "Static"
    sku               = "Standard"
  }
}

variable "deploy_nginx_demo" {
  type = object({
    deploy = bool
    name   = string
    image  = string
    port   = number
    path   = string
    labels = map(string)
  })
  default = {
    deploy = false
    name   = "nginx"
    image  = "nginx:1.21.6"
    port   = 80
    path   = "/demo"
    labels = {
      app = "nginx"
    }
  }
}

variable "airflow_custom_image" {
  type = object({
    dockerfile_path = string
    acr_image_path  = string
  })
  default = {
    dockerfile_path = "../docker/airflow"
    acr_image_path  = "airflow"
  }
}

variable "airflow" {
  type = object({
    chart_name                  = string
    chart_version               = string
    keyvault_connections_prefix = string
    keyvault_variables_prefix   = string
    fernet_key                  = string
    webserver_secret_key        = string
    dag_repository = object({
      repo    = string
      branch  = string
      subPath = string
    })
    default_user = object({
      username = string
      password = string
    })
  })
  default = {
    chart_name                  = "airflow"
    chart_version               = "1.9.0"
    keyvault_connections_prefix = "airflow-connections"
    keyvault_variables_prefix   = "airflow-variables"
    fernet_key                  = "nXjlv8Ipvvaq-dTLzT9u_j7dOG7ZX5-GLeza6LRctFQ="
    webserver_secret_key        = "06d12648d9f535f8c5e51c9e9a49571b"
    dag_repository = {
      repo    = "https://github.com/tmissao/airflow-kubernetes-azure"
      branch  = "master"
      subPath = "python/dags"
    }
    default_user = {
      username = "admin"
      password = "admin"
    }
  }
}

variable "tags" {
  type = map(string)
  default = {
    "environment" = "poc"
  }
}