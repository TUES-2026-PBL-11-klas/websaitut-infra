output "cms_fqdns" {
  description = "Directus CMS FQDNs per environment"
  value       = { for k, v in module.cms : k => v.fqdn }
}

output "website_fqdns" {
  description = "Website FQDNs per environment"
  value       = { for k, v in module.website : k => v.fqdn }
}

output "postgres_fqdn" {
  description = "PostgreSQL server FQDN"
  value       = module.database.server_fqdn
}

output "cicd_identity_client_ids" {
  description = "Client IDs for CI/CD identities — feed into GitHub Actions OIDC"
  value       = { for k, v in azurerm_user_assigned_identity.cicd : k => v.client_id }
}

output "keyvault_uris" {
  description = "Key Vault URIs per vault"
  value = merge(
    { shared = module.key_vault_shared.vault_uri },
    { for k, v in module.key_vault_env : k => v.vault_uri },
  )
}
