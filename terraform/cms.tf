locals {
  cms_plain_env = {
    for env in local.environments : env => {
      DB_CLIENT                    = "pg"
      DB_HOST                      = azurerm_postgresql_flexible_server.main.fqdn
      DB_PORT                      = "5432"
      DB_DATABASE                  = "directus-${env}"
      DB_USER                      = "directus"
      DB_SSL                       = "true"
      ADMIN_EMAIL                  = var.directus_admin_email
      PUBLIC_URL                   = var.directus_public_urls[env]
      STORAGE_LOCATIONS            = "azure"
      STORAGE_AZURE_DRIVER         = "azure"
      STORAGE_AZURE_CONTAINER_NAME = "media-${env}"
      STORAGE_AZURE_ACCOUNT_NAME   = azurerm_storage_account.media.name
      CORS_ENABLED                 = "true"
      CORS_ORIGIN                  = "true"
      CACHE_ENABLED                = "true"
      CACHE_AUTO_PURGE             = "true"
      CACHE_TTL                    = "5m"
      RATE_LIMITER_ENABLED         = "true"
      RATE_LIMITER_POINTS          = "50"
      RATE_LIMITER_DURATION        = "1"
      RATE_LIMITER_STORE           = "memory"
      LOG_LEVEL                    = "info"
      MAX_PAYLOAD_SIZE             = "10mb"
      TELEMETRY                    = "false"
    }
  }

  cms_secret_env = {
    DB_PASSWORD               = "db-password"
    ADMIN_PASSWORD            = "admin-password"
    KEY                       = "key"
    SECRET                    = "secret"
    STORAGE_AZURE_ACCOUNT_KEY = "storage-azure-account-key"
  }
}

resource "azurerm_container_app" "cms" {
  for_each = local.environments

  name                         = "ca-cms-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.app["cms-${each.key}"].id]
  }

  dynamic "secret" {
    for_each = local.cms_secret_ids[each.key]
    content {
      name                = secret.key
      key_vault_secret_id = secret.value
      identity            = azurerm_user_assigned_identity.app["cms-${each.key}"].id
    }
  }

  template {
    min_replicas = local.app_config[each.key].min_replicas
    max_replicas = 10

    container {
      name   = "cms"
      image  = var.directus_image
      cpu    = local.app_config[each.key].cpu
      memory = local.app_config[each.key].memory

      dynamic "env" {
        for_each = local.cms_plain_env[each.key]
        content {
          name  = env.key
          value = env.value
        }
      }

      dynamic "env" {
        for_each = local.cms_secret_env
        content {
          name        = env.key
          secret_name = env.value
        }
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8055
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  tags       = merge(local.common_tags, { environment = each.key })
  depends_on = [time_sleep.wait_for_kv_rbac]
}
