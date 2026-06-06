output "id" {
  value = azurerm_key_vault.this.id
}

output "vault_uri" {
  value = azurerm_key_vault.this.vault_uri
}

output "secret_ids" {
  description = "Map of secret name => versionless_id for all managed secrets"
  value = merge(
    { for k, v in azurerm_key_vault_secret.this : k => v.versionless_id },
    { for k, v in azurerm_key_vault_secret.placeholder : k => v.versionless_id }
  )
}
