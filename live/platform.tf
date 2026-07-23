# Shared compute & storage foundation. Three resources without independent
# lifecycles — log analytics feeds the container app environment, storage is
# the media backing for all environments.

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-website"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = 30
  tags                = merge(local.common_tags, { environment = "shared" })
}

# infrastructure_resource_group_name is set explicitly because Azure otherwise
# auto-generates an ugly MC_-style RG name that we can't tag/move.
resource "azurerm_container_app_environment" "main" {
  name                               = "cae-website"
  location                           = azurerm_resource_group.main.location
  resource_group_name                = azurerm_resource_group.main.name
  infrastructure_subnet_id           = module.networking.apps_subnet_id
  infrastructure_resource_group_name = "rg-cae"
  log_analytics_workspace_id         = azurerm_log_analytics_workspace.main.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }

  tags = merge(local.common_tags, { environment = "shared" })
}

resource "azurerm_storage_account" "media" {
  name                            = "mediaelsys"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false
  tags                            = merge(local.common_tags, { environment = "shared" })
}
