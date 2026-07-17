locals {
  website_per_env = {
    staging = { min_replicas = 0, image = var.images["staging"], domain = "staging.elsys.website" }
    prod    = { min_replicas = 1, image = var.images["prod"], domain = "elsys.website" }
  }
}

data "azurerm_key_vault_secret" "ghcr_password" {
  name         = "ghcr-password"
  key_vault_id = module.key_vault_shared.id
}

resource "azurerm_user_assigned_identity" "website" {
  for_each            = local.website_per_env
  name                = "id-website-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(local.common_tags, { environment = each.key })
}

module "website" {
  source   = "./modules/container_app"
  for_each = local.website_per_env

  name                         = "ca-website-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  identity_id                  = azurerm_user_assigned_identity.website[each.key].id
  image                        = each.value.image
  port                         = 3000
  min_replicas                 = each.value.min_replicas
  custom_domains               = [each.value.domain]

  plain_env = {
    DIRECTUS_URL = "http://ca-cms-${each.key}"
  }

  secrets = {
    "ghcr-password" = data.azurerm_key_vault_secret.ghcr_password.versionless_id
  }

  registry = {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-password"
  }

  liveness_probe = {
    transport     = "TCP"
    port          = 3000
    initial_delay = 0
    timeout       = 5
  }

  readiness_probe = {
    transport               = "TCP"
    port                    = 3000
    interval_seconds        = 5
    timeout                 = 5
    failure_count_threshold = 48
    success_count_threshold = 1
  }

  startup_probe = {
    transport               = "TCP"
    port                    = 3000
    failure_count_threshold = 240
    interval_seconds        = 1
    timeout                 = 3
    initial_delay           = 1
  }

  tags = merge(local.common_tags, { environment = each.key, app = "website" })
}
