resource "azurerm_resource_group" "main" {
  name     = "rg-website"
  location = var.location

  tags = merge(local.common_tags, { environment = "shared" })
}

locals {
  environments = toset(["staging", "prod"])

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

