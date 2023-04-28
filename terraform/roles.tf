resource "azurerm_role_assignment" "network_aks_contributor_rg" {
  scope                = azurerm_resource_group.this.id
  role_definition_name = "Network Contributor"
  principal_id         = one(azurerm_kubernetes_cluster.this.identity).principal_id
}

resource "azurerm_role_assignment" "allow_aks_to_pull" {
  principal_id                     = one(azurerm_kubernetes_cluster.this.kubelet_identity).object_id
  role_definition_name             = "AcrPull"
  scope                            = azurerm_container_registry.this.id
}

resource "azurerm_role_assignment" "allow_user_to_pull_push" {
  for_each = toset(["AcrPull", "AcrPush"])
  principal_id                     = data.azurerm_client_config.current.object_id
  role_definition_name             = each.value
  scope                            = azurerm_container_registry.this.id
}