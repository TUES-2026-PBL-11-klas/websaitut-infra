output "cms_fqdn" {
  value = azurerm_container_app.cms.ingress[0].fqdn
}

output "website_fqdn" {
  value = azurerm_container_app.website.ingress[0].fqdn
}

output "postgres_fqdn" {
  value = azurerm_postgresql_flexible_server.main.fqdn
}

output "cms_key_vault_uri" {
  value = azurerm_key_vault.main.vault_uri
}

output "website_key_vault_uri" {
  value = azurerm_key_vault.website.vault_uri
}
