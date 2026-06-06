# State migration: individual KV secret resources → for_each groups
# Safe to delete this file after the first successful terraform apply.

moved {
  from = azurerm_key_vault_secret.staging_directus_admin_password
  to   = azurerm_key_vault_secret.staging["directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_key
  to   = azurerm_key_vault_secret.staging["directus-key"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_secret
  to   = azurerm_key_vault_secret.staging["directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_db_password
  to   = azurerm_key_vault_secret.staging["directus-db-password"]
}

moved {
  from = azurerm_key_vault_secret.prod_directus_admin_password
  to   = azurerm_key_vault_secret.shared["prod-directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_key
  to   = azurerm_key_vault_secret.shared["prod-directus-key"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_secret
  to   = azurerm_key_vault_secret.shared["prod-directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_db_password
  to   = azurerm_key_vault_secret.shared["prod-directus-db-password"]
}
moved {
  from = azurerm_key_vault_secret.pg_admin_password
  to   = azurerm_key_vault_secret.shared["pg-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.ghcr_password
  to   = azurerm_key_vault_secret.shared["ghcr-password"]
}
moved {
  from = azurerm_key_vault_secret.storage_account_key
  to   = azurerm_key_vault_secret.shared["storage-account-key"]
}

moved {
  from = azurerm_key_vault_secret.staging_directus_token
  to   = azurerm_key_vault_secret.token["staging"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_token
  to   = azurerm_key_vault_secret.token["prod"]
}
