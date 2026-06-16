output "cms_fqdns" {
  description = "Directus CMS FQDNs per environment"
  value = merge(
    { staging = module.staging.cms_fqdn },
    { for env, m in module.cms : env => m.fqdn }
  )
}

output "website_fqdns" {
  description = "Website FQDNs per environment"
  value = merge(
    { staging = module.staging.website_fqdn },
    { for env, m in module.website : env => m.fqdn }
  )
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.database.server_fqdn
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}
