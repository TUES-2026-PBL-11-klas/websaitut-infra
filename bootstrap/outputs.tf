output "resource_group_name" {
  description = "State backend resource group — feeds live/versions.tf backend block"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "State backend storage account — feeds live/versions.tf backend block"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "State backend blob container — feeds live/versions.tf backend block"
  value       = azurerm_storage_container.tfstate.name
}
