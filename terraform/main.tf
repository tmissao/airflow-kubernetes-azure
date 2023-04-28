resource "azurerm_resource_group" "this" {
  name     = var.resource_group.name
  location = var.resource_group.location
  tags     = local.tags
}

resource "azurerm_virtual_network" "this" {
  name                = var.virtual_network.name
  address_space       = var.virtual_network.address_space
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  tags = local.tags
}

resource "azurerm_subnet" "this" {
  name                 = var.virtual_network.subnet.name
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = var.virtual_network.subnet.address_prefixes
}

resource "azurerm_network_security_group" "this" {
  name                = var.virtual_network_security_rules.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  dynamic "security_rule" {
    for_each = var.virtual_network_security_rules.rules
    content {
      name                       = security_rule.value.name
      priority                   = security_rule.value.priority
      direction                  = security_rule.value.direction
      access                     = security_rule.value.access
      protocol                   = security_rule.value.protocol
      source_port_range          = security_rule.value.source_port_range
      destination_port_range     = security_rule.value.destination_port_range
      source_address_prefix      = security_rule.value.source_address_prefix
      destination_address_prefix = security_rule.value.destination_address_prefix
    }
  }
  tags = local.tags
}

resource "azurerm_subnet_network_security_group_association" "this" {
  subnet_id                 = azurerm_subnet.this.id
  network_security_group_id = azurerm_network_security_group.this.id
}

resource "azurerm_container_registry" "this" {
  name                = var.acr.name
  resource_group_name = azurerm_resource_group.this.name
  location            = azurerm_resource_group.this.location
  sku                 = var.acr.sku
  tags = local.tags
}

resource "azurerm_storage_account" "this" {
  name                     = var.storage_account.name
  resource_group_name      = azurerm_resource_group.this.name
  location                 = azurerm_resource_group.this.location
  account_tier             = var.storage_account.tier
  account_replication_type = var.storage_account.account_replication_type
  tags = local.tags
}

resource "azurerm_storage_container" "this" {
  name                  = "airflow"
  storage_account_name  = azurerm_storage_account.this.name
  container_access_type = "private"
}

resource "azurerm_kubernetes_cluster" "this" {
  name = var.kubernetes.name
  location = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  kubernetes_version = var.kubernetes.version
  dns_prefix = var.kubernetes.name
  default_node_pool {
    name = var.kubernetes.default_node_pool.name
    enable_auto_scaling = var.kubernetes.default_node_pool.enable_auto_scaling
    max_count = var.kubernetes.default_node_pool.max_count
    node_count = var.kubernetes.default_node_pool.node_count
    min_count = var.kubernetes.default_node_pool.min_count
    vm_size = var.kubernetes.default_node_pool.vm_size
    node_labels = var.kubernetes.default_node_pool.node_labels
    vnet_subnet_id = azurerm_subnet.this.id
    tags = local.tags
  }
  network_profile {
    network_plugin = var.kubernetes.network_profile.network_plugin
    network_policy = var.kubernetes.network_profile.network_policy
    load_balancer_sku = var.kubernetes.network_profile.load_balancer_sku
    dns_service_ip = cidrhost(var.kubernetes.network_profile.service_cidr, 10)
    service_cidr   = var.kubernetes.network_profile.service_cidr
    docker_bridge_cidr = var.kubernetes.network_profile.docker_bridge_cidr
  }
  identity {
    type = "SystemAssigned"
  }
  tags = local.tags
}

resource "random_password" "postgres" {
  length           = 16
  special          = false
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                   = var.postgres.name
  resource_group_name    = azurerm_resource_group.this.name
  location               = azurerm_resource_group.this.location
  version                = var.postgres.version
  administrator_login    = var.postgres.administrator_login
  administrator_password = random_password.postgres.result
  storage_mb             = var.postgres.storage_mb
  sku_name               = var.postgres.sku_name
  zone = var.postgres.zone
  tags = local.tags
}

resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = "airflow"
  server_id = azurerm_postgresql_flexible_server.this.id
  collation = "en_US.utf8"
  charset   = "utf8"
}

resource "azurerm_postgresql_flexible_server_firewall_rule" "this" {
  for_each = var.postgres.allowed_to_connect_ips
  name             = each.key
  server_id        = azurerm_postgresql_flexible_server.this.id
  start_ip_address = each.value.start_ip_address
  end_ip_address   = each.value.end_ip_address
}

resource "azurerm_redis_cache" "this" {
  name                = var.redis.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  capacity            = var.redis.capacity
  family              = var.redis.family
  sku_name            = var.redis.sku_name
  enable_non_ssl_port = var.redis.enable_non_ssl_port
  redis_version = var.redis.redis_version
  redis_configuration {
    enable_authentication = var.redis.redis_configuration.enable_authentication
  }
  tags = local.tags
}

resource "azurerm_public_ip" "this" {
  name                = var.nginx_public_ip.name
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  allocation_method = var.nginx_public_ip.allocation_method
  sku               = var.nginx_public_ip.sku
  tags = local.tags
}

resource "null_resource" "build_airflow_docker_image" {
  triggers = {
    DOCKERFILE_HASH = filemd5("${var.airflow_custom_image.dockerfile_path}/Dockerfile")
  }
  provisioner "local-exec" {
    command = "/bin/bash ./scripts/build-image.sh"
    environment = {
      ACR_REGISTRY_NAME  = azurerm_container_registry.this.name
      ACR_IMAGE_PATH  = var.airflow_custom_image.acr_image_path
      DOCKERFILE_PATH = var.airflow_custom_image.dockerfile_path
    }
  }
  depends_on = [
    azurerm_role_assignment.allow_user_to_pull_push
  ]
}