module "website" {
  source = "../container_app"

  name                         = "ca-website-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  identity_id                  = azurerm_user_assigned_identity.website.id
  image                        = var.website_image
  port                         = 3000
  min_replicas                 = var.app_config.min_replicas
  cpu                          = var.app_config.cpu
  memory                       = var.app_config.memory

  secrets = {
    "ghcr-password" = var.ghcr_password_secret_id
  }

  plain_env = {
    DIRECTUS_URL = "http://ca-cms-${var.environment}"
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

  tags = var.tags
}
