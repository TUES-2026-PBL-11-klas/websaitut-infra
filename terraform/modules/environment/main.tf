data "azurerm_key_vault_secret" "directus_admin_password" {
  name         = "directus-admin-password"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_key" {
  name         = "directus-key"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_secret" {
  name         = "directus-secret"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_db_password" {
  name         = "directus-db-password"
  key_vault_id = var.key_vault_id
}
