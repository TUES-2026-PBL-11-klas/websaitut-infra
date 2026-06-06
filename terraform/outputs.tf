output "cms_fqdns" {
  description = "Directus CMS FQDNs per environment"
  value       = { for env, app in azurerm_container_app.cms : env => app.ingress[0].fqdn }
}

output "website_fqdns" {
  description = "Website FQDNs per environment"
  value       = { for env, app in azurerm_container_app.website : env => app.ingress[0].fqdn }
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = azurerm_postgresql_flexible_server.main.fqdn
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = azurerm_key_vault.main.vault_uri
}

output "pg_admin_password" {
  description = "PostgreSQL admin password (read from KV or here)"
  value       = random_password.pg_admin.result
  sensitive   = true
}

output "staging_directus_db_password" {
  description = "Staging Directus DB password (for PG role creation)"
  value       = random_password.staging["directus-db-password"].result
  sensitive   = true
}
