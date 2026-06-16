output "cms_fqdns" {
  description = "Directus CMS FQDNs per environment"
  value       = { for env, m in module.cms : env => m.fqdn }
}

output "website_fqdns" {
  description = "Website FQDNs per environment"
  value       = { for env, m in module.website : env => m.fqdn }
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}
