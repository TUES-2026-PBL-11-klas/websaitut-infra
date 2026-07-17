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

output "deploy_identity_client_ids" {
  description = "Client IDs for CD identities — feed into GitHub environment secrets"
  value       = { for k, v in azurerm_user_assigned_identity.deploy : k => v.client_id }
}

output "cae_static_ip" {
  description = "CAE ingress IP — target for apex A records"
  value       = azurerm_container_app_environment.main.static_ip_address
}

output "custom_domain_verification_id" {
  description = "Value for the asuid.<host> TXT records that prove domain ownership"
  value       = azurerm_container_app_environment.main.custom_domain_verification_id
}

output "keyvault_uris" {
  description = "Key Vault URIs per vault"
  value = merge(
    { shared = module.key_vault_shared.vault_uri },
    { for k, v in module.key_vault_env : k => v.vault_uri },
  )
}
