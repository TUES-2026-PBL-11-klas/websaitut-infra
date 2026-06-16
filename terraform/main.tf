resource "azurerm_resource_group" "main" {
  name     = "rg-website"
  location = var.location

  tags = merge(local.common_tags, { environment = "shared" })
}

locals {
  # Shrinks as environments migrate into module "staging"/"prod" (Step 8/9).
  # Drives the remaining flat for_each resources until Step 10 removes them.
  environments = toset(["prod"])

  common_tags = {
    project    = "website"
    managed_by = "terraform"
  }

  app_config = {
    staging = {
      min_replicas = 0
      cpu          = 0.5
      memory       = "1Gi"
    }
    prod = {
      min_replicas = 1
      cpu          = 0.5
      memory       = "1Gi"
    }
  }
}

module "networking" {
  source              = "./modules/networking"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = merge(local.common_tags, { environment = "shared" })
}

module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  delegated_subnet_id = module.networking.postgres_subnet_id
  vnet_id             = module.networking.vnet_id
  admin_login         = "elsys_pgadmin"
  admin_password      = data.azurerm_key_vault_secret.pg_admin_password.value
  tags                = merge(local.common_tags, { environment = "shared" })
}

module "container_platform" {
  source                   = "./modules/container_platform"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  infrastructure_subnet_id = module.networking.apps_subnet_id
  tags                     = merge(local.common_tags, { environment = "shared" })
}

module "storage" {
  source              = "./modules/storage"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tags                = merge(local.common_tags, { environment = "shared" })
}

module "staging" {
  source      = "./modules/environment"
  environment = "staging"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location

  postgres_server_id                       = module.database.server_id
  postgres_server_fqdn                     = module.database.server_fqdn
  container_app_environment_id             = module.container_platform.environment_id
  container_app_environment_default_domain = module.container_platform.environment_default_domain
  storage_account_id                       = module.storage.account_id
  storage_account_name                     = module.storage.account_name
  key_vault_id                             = module.key_vault.id

  app_config    = local.app_config["staging"]
  cms_image     = var.directus_image
  website_image = var.images["staging"]

  directus_admin_email          = var.directus_admin_email
  ghcr_username                 = var.ghcr_username
  ghcr_password_secret_id       = data.azurerm_key_vault_secret.ghcr_password.versionless_id
  storage_account_key_secret_id = data.azurerm_key_vault_secret.storage_account_key.versionless_id

  tags = merge(local.common_tags, { environment = "staging" })
}

