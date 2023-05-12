terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "3.48.0"
    }
    azuread = {
      source  = "hashicorp/azuread"
      version = "2.38.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.19.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.9.0"
    }
  }
}

provider "azuread" {}

provider "azurerm" {
  features {
    key_vault {
      purge_soft_delete_on_destroy    = true
      recover_soft_deleted_key_vaults = true
    }
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
  }
}

provider "kubernetes" {
  host                   = azurerm_kubernetes_cluster.this.kube_config.0.host
  username               = azurerm_kubernetes_cluster.this.kube_config.0.username
  password               = azurerm_kubernetes_cluster.this.kube_config.0.password
  client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
}

provider "helm" {
  kubernetes {
    host                   = azurerm_kubernetes_cluster.this.kube_config.0.host
    client_certificate     = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_certificate)
    client_key             = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.client_key)
    cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.this.kube_config.0.cluster_ca_certificate)
  }
}