output "environment_id" {
  value = azurerm_container_app_environment.this.id
}

output "environment_name" {
  value = azurerm_container_app_environment.this.name
}

output "environment_default_domain" {
  value = azurerm_container_app_environment.this.default_domain
}

output "log_analytics_workspace_id" {
  value = azurerm_log_analytics_workspace.this.id
}
