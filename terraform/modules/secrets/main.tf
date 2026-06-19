variable "key_vault_id" {
  type = string
}

variable "names" {
  type        = map(string)
  description = "logical-name => key-vault-secret-name"
}

data "azurerm_key_vault_secret" "this" {
  for_each     = var.names
  name         = each.value
  key_vault_id = var.key_vault_id
}

output "versionless_ids" {
  value = { for k, v in data.azurerm_key_vault_secret.this : k => v.versionless_id }
}
