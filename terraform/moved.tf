# ── KV vault & infra ────────────────────────────────────────────────────────

moved {
  from = azurerm_key_vault.main
  to   = module.key_vault.azurerm_key_vault.this
}

moved {
  from = azurerm_role_assignment.kv_admin
  to   = module.key_vault.azurerm_role_assignment.admin
}

moved {
  from = azurerm_role_assignment.kv_secrets_user["cms-staging"]
  to   = module.key_vault.azurerm_role_assignment.secrets_user["cms-staging"]
}
moved {
  from = azurerm_role_assignment.kv_secrets_user["cms-prod"]
  to   = module.key_vault.azurerm_role_assignment.secrets_user["cms-prod"]
}
moved {
  from = azurerm_role_assignment.kv_secrets_user["website-staging"]
  to   = module.key_vault.azurerm_role_assignment.secrets_user["website-staging"]
}
moved {
  from = azurerm_role_assignment.kv_secrets_user["website-prod"]
  to   = module.key_vault.azurerm_role_assignment.secrets_user["website-prod"]
}

moved {
  from = time_sleep.wait_for_kv_rbac
  to   = module.key_vault.time_sleep.rbac
}

moved {
  from = azurerm_private_dns_zone.keyvault
  to   = module.key_vault.azurerm_private_dns_zone.this
}
moved {
  from = azurerm_private_dns_zone_virtual_network_link.keyvault
  to   = module.key_vault.azurerm_private_dns_zone_virtual_network_link.this
}
moved {
  from = azurerm_private_endpoint.keyvault
  to   = module.key_vault.azurerm_private_endpoint.this
}

# ── KV secrets: staging (for_each group → module, key renamed) ──────────────

moved {
  from = azurerm_key_vault_secret.staging_directus_admin_password
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_key
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-key"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_secret
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.staging_directus_db_password
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-db-password"]
}

moved {
  from = azurerm_key_vault_secret.staging["directus-admin-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.staging["directus-key"]
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-key"]
}
moved {
  from = azurerm_key_vault_secret.staging["directus-secret"]
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.staging["directus-db-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["staging-directus-db-password"]
}

# ── KV secrets: shared ────────────────────────────────────────────────────────

moved {
  from = azurerm_key_vault_secret.prod_directus_admin_password
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_key
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-key"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_secret
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_db_password
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-db-password"]
}
moved {
  from = azurerm_key_vault_secret.pg_admin_password
  to   = module.key_vault.azurerm_key_vault_secret.this["pg-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.ghcr_password
  to   = module.key_vault.azurerm_key_vault_secret.this["ghcr-password"]
}
moved {
  from = azurerm_key_vault_secret.storage_account_key
  to   = module.key_vault.azurerm_key_vault_secret.this["storage-account-key"]
}

moved {
  from = azurerm_key_vault_secret.shared["prod-directus-admin-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.shared["prod-directus-key"]
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-key"]
}
moved {
  from = azurerm_key_vault_secret.shared["prod-directus-secret"]
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-secret"]
}
moved {
  from = azurerm_key_vault_secret.shared["prod-directus-db-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["prod-directus-db-password"]
}
moved {
  from = azurerm_key_vault_secret.shared["pg-admin-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["pg-admin-password"]
}
moved {
  from = azurerm_key_vault_secret.shared["ghcr-password"]
  to   = module.key_vault.azurerm_key_vault_secret.this["ghcr-password"]
}
moved {
  from = azurerm_key_vault_secret.shared["storage-account-key"]
  to   = module.key_vault.azurerm_key_vault_secret.this["storage-account-key"]
}

# ── KV secrets: tokens (placeholder) ─────────────────────────────────────────

moved {
  from = azurerm_key_vault_secret.staging_directus_token
  to   = module.key_vault.azurerm_key_vault_secret.placeholder["staging-directus-token"]
}
moved {
  from = azurerm_key_vault_secret.prod_directus_token
  to   = module.key_vault.azurerm_key_vault_secret.placeholder["prod-directus-token"]
}

moved {
  from = azurerm_key_vault_secret.token["staging"]
  to   = module.key_vault.azurerm_key_vault_secret.placeholder["staging-directus-token"]
}
moved {
  from = azurerm_key_vault_secret.token["prod"]
  to   = module.key_vault.azurerm_key_vault_secret.placeholder["prod-directus-token"]
}

# ── Container apps ───────────────────────────────────────────────────────────

moved {
  from = azurerm_container_app.cms["staging"]
  to   = module.cms["staging"].azurerm_container_app.this
}
moved {
  from = azurerm_container_app.cms["prod"]
  to   = module.cms["prod"].azurerm_container_app.this
}

moved {
  from = azurerm_container_app.website["staging"]
  to   = module.website["staging"].azurerm_container_app.this
}
moved {
  from = azurerm_container_app.website["prod"]
  to   = module.website["prod"].azurerm_container_app.this
}
