output "vnet_id" {
  value = azurerm_virtual_network.this.id
}

output "vnet_name" {
  value = azurerm_virtual_network.this.name
}

output "apps_subnet_id" {
  value = azurerm_subnet.apps.id
}

output "postgres_subnet_id" {
  value = azurerm_subnet.postgres.id
}

output "endpoints_subnet_id" {
  value = azurerm_subnet.endpoints.id
}

output "key_vault_private_dns_zone_id" {
  value = azurerm_private_dns_zone.key_vault.id
}
