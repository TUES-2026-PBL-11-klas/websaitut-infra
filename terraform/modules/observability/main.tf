resource "azurerm_log_analytics_workspace" "this" {
  name                = "log-website"
  location            = var.location
  resource_group_name = var.resource_group_name
  retention_in_days   = 30

  tags = var.tags
}
