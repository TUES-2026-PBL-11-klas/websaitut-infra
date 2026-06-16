output "cms_fqdns" {
  description = "Directus CMS FQDNs per environment"
  value = {
    staging = module.staging.cms_fqdn
    prod    = module.prod.cms_fqdn
  }
}

output "website_fqdns" {
  description = "Website FQDNs per environment"
  value = {
    staging = module.staging.website_fqdn
    prod    = module.prod.website_fqdn
  }
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.database.server_fqdn
}

output "keyvault_uri" {
  description = "Key Vault URI"
  value       = module.key_vault.vault_uri
}
