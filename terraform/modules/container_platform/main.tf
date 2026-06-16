resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-website"
  location            = var.location
  resource_group_name = var.resource_group_name
  retention_in_days   = 30

  tags = var.tags
}

resource "azurerm_container_app_environment" "this" {
  name                               = "cae-website"
  location                           = var.location
  resource_group_name                = var.resource_group_name
  infrastructure_subnet_id           = var.infrastructure_subnet_id
  infrastructure_resource_group_name = "rg-cae"
  log_analytics_workspace_id         = azurerm_log_analytics_workspace.this.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = var.tags
}
