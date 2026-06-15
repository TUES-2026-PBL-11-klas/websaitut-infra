module "website" {
  for_each = local.environments
  source   = "./modules/container_app"

  name                         = "ca-website-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  identity_id                  = azurerm_user_assigned_identity.app["website-${each.key}"].id
  image                        = var.images[each.key]
  port                         = 3000
  min_replicas                 = local.app_config[each.key].min_replicas
  cpu                          = local.app_config[each.key].cpu
  memory                       = local.app_config[each.key].memory

  secrets = local.website_secret_ids[each.key]

  plain_env = {
    DIRECTUS_URL = "http://ca-cms-${each.key}"
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

  tags = merge(local.common_tags, { environment = each.key })
}
