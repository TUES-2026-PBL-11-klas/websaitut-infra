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

output "keyvault_uris" {
  description = "Key Vault URIs per vault"
  value = {
    shared  = module.key_vault_shared.vault_uri
    staging = module.key_vault_staging.vault_uri
    prod    = module.key_vault_prod.vault_uri
  }
}
