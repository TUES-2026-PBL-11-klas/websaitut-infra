resource "azurerm_user_assigned_identity" "app" {
  for_each            = toset(["cms-staging", "cms-prod", "website-staging", "website-prod"])
  name                = "id-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    environment = split("-", each.key)[length(split("-", each.key)) - 1]
  })
}

module "key_vault" {
  source              = "./modules/key_vault"
  name                = "kv-elsys-website"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id
  subnet_id           = module.networking.endpoints_subnet_id
  vnet_id             = module.networking.vnet_id

  principal_ids = {
    for k, v in azurerm_user_assigned_identity.app : k => v.principal_id
  }

  tags = merge(local.common_tags, { environment = "shared" })
}

# Shared secrets — bootstrapped externally, read via data sources
data "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "ghcr_password" {
  name         = "ghcr-password"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  key_vault_id = module.key_vault.id
}

# Per-env CMS secrets — bootstrapped externally, move to environment module in Step 8
data "azurerm_key_vault_secret" "cms_admin_password" {
  for_each     = local.environments
  name         = "${each.key}-directus-admin-password"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "cms_db_password" {
  for_each     = local.environments
  name         = "${each.key}-directus-db-password"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "cms_key" {
  for_each     = local.environments
  name         = "${each.key}-directus-key"
  key_vault_id = module.key_vault.id
}

data "azurerm_key_vault_secret" "cms_secret" {
  for_each     = local.environments
  name         = "${each.key}-directus-secret"
  key_vault_id = module.key_vault.id
}

locals {
  cms_secret_ids = {
    for env in local.environments : env => {
      "admin-password"            = data.azurerm_key_vault_secret.cms_admin_password[env].versionless_id
      "db-password"               = data.azurerm_key_vault_secret.cms_db_password[env].versionless_id
      "key"                       = data.azurerm_key_vault_secret.cms_key[env].versionless_id
      "secret"                    = data.azurerm_key_vault_secret.cms_secret[env].versionless_id
      "storage-azure-account-key" = data.azurerm_key_vault_secret.storage_account_key.versionless_id
    }
  }

  website_secret_ids = {
    for env in local.environments : env => {
      "ghcr-password" = data.azurerm_key_vault_secret.ghcr_password.versionless_id
    }
  }
}
