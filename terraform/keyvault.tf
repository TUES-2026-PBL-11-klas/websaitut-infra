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
  subnet_id           = azurerm_subnet.endpoints.id
  vnet_id             = azurerm_virtual_network.main.id

  principal_ids = {
    for k, v in azurerm_user_assigned_identity.app : k => v.principal_id
  }

  secrets = {
    "staging-directus-admin-password" = random_password.staging["directus-admin-password"].result
    "staging-directus-key"            = random_password.staging["directus-key"].result
    "staging-directus-secret"         = random_password.staging["directus-secret"].result
    "staging-directus-db-password"    = random_password.staging["directus-db-password"].result
    "prod-directus-admin-password"    = var.prod_directus_admin_password
    "prod-directus-key"               = var.prod_directus_key
    "prod-directus-secret"            = var.prod_directus_secret
    "prod-directus-db-password"       = var.prod_directus_db_password
    "pg-admin-password"               = random_password.pg_admin.result
    "ghcr-password"                   = var.ghcr_password
    "storage-account-key"             = azurerm_storage_account.media.primary_access_key
  }

  placeholder_secrets = {
    "staging-directus-token" = "placeholder"
    "prod-directus-token"    = "placeholder"
  }

  tags = merge(local.common_tags, { environment = "shared" })
}

locals {
  cms_secret_ids = {
    staging = {
      "admin-password"            = module.key_vault.secret_ids["staging-directus-admin-password"]
      "db-password"               = module.key_vault.secret_ids["staging-directus-db-password"]
      "key"                       = module.key_vault.secret_ids["staging-directus-key"]
      "secret"                    = module.key_vault.secret_ids["staging-directus-secret"]
      "storage-azure-account-key" = module.key_vault.secret_ids["storage-account-key"]
    }
    prod = {
      "admin-password"            = module.key_vault.secret_ids["prod-directus-admin-password"]
      "db-password"               = module.key_vault.secret_ids["prod-directus-db-password"]
      "key"                       = module.key_vault.secret_ids["prod-directus-key"]
      "secret"                    = module.key_vault.secret_ids["prod-directus-secret"]
      "storage-azure-account-key" = module.key_vault.secret_ids["storage-account-key"]
    }
  }

  website_secret_ids = {
    staging = {
      "ghcr-password"  = module.key_vault.secret_ids["ghcr-password"]
      "directus-token" = module.key_vault.secret_ids["staging-directus-token"]
    }
    prod = {
      "ghcr-password"  = module.key_vault.secret_ids["ghcr-password"]
      "directus-token" = module.key_vault.secret_ids["prod-directus-token"]
    }
  }
}
