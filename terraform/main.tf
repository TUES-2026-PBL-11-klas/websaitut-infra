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

