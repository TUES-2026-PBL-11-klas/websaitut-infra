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

resource "random_password" "pg_admin" {
  length           = 32
  special          = true
  override_special = "!@#$%"
}

resource "random_password" "staging" {
  for_each         = toset(["directus-admin-password", "directus-key", "directus-secret", "directus-db-password"])
  length           = 32
  special          = true
  override_special = "!@#$%"
}
