data "azurerm_key_vault_secret" "directus_admin_password" {
  name         = "${var.environment}-directus-admin-password"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_key" {
  name         = "${var.environment}-directus-key"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_secret" {
  name         = "${var.environment}-directus-secret"
  key_vault_id = var.key_vault_id
}

data "azurerm_key_vault_secret" "directus_db_password" {
  name         = "${var.environment}-directus-db-password"
  key_vault_id = var.key_vault_id
}
