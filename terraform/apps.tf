# ──────────────────────────────────────────────
#  Log Analytics (required by CAE)
# ──────────────────────────────────────────────

resource "azurerm_log_analytics_workspace" "main" {
  name                = "log-website-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  retention_in_days   = 30
}

# ──────────────────────────────────────────────
#  Container App Environment
# ──────────────────────────────────────────────

resource "azurerm_container_app_environment" "main" {
  name                           = "cae-${var.environment}"
  location                       = var.location
  resource_group_name            = azurerm_resource_group.main.name
  infrastructure_subnet_id       = azurerm_subnet.apps.id
  infrastructure_resource_group_name = "ME_cae-${var.environment}_${azurerm_resource_group.main.name}_${var.location}"
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.main.id

  workload_profile {
    name                  = "Consumption"
    workload_profile_type = "Consumption"
  }
}

# ──────────────────────────────────────────────
#  Directus CMS
# ──────────────────────────────────────────────

resource "azurerm_container_app" "cms" {
  name                         = "ca-cms-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type = "SystemAssigned"
  }

  dynamic "secret" {
    for_each = {
      "admin-password"           = azurerm_key_vault_secret.directus_admin_password.versionless_id
      "db-password"              = azurerm_key_vault_secret.directus_db_password.versionless_id
      "key"                      = azurerm_key_vault_secret.directus_key.versionless_id
      "secret"                   = azurerm_key_vault_secret.directus_secret.versionless_id
      "storage-azure-account-key" = azurerm_key_vault_secret.storage_account_key.versionless_id
    }
    content {
      name                = secret.key
      identity            = "System"
      key_vault_secret_id = secret.value
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

  template {
    min_replicas = 1

    container {
      name   = "ca-cms-${var.environment}"
      image  = var.directus_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = {
          DB_CLIENT                    = { value = "pg" }
          DB_HOST                      = { value = azurerm_postgresql_flexible_server.main.fqdn }
          DB_PORT                      = { value = "5432" }
          DB_DATABASE                  = { value = "directus" }
          DB_USER                      = { value = "directus" }
          DB_SSL                       = { value = "true" }
          DB_PASSWORD                  = { secret = "db-password" }
          ADMIN_EMAIL                  = { value = var.directus_admin_email }
          ADMIN_PASSWORD               = { secret = "admin-password" }
          KEY                          = { secret = "key" }
          SECRET                       = { secret = "secret" }
          PUBLIC_URL                   = { value = var.directus_public_url }
          STORAGE_LOCATIONS            = { value = "azure" }
          STORAGE_AZURE_DRIVER         = { value = "azure" }
          STORAGE_AZURE_CONTAINER_NAME = { value = "media" }
          STORAGE_AZURE_ACCOUNT_NAME   = { value = azurerm_storage_account.media.name }
          STORAGE_AZURE_ACCOUNT_KEY    = { secret = "storage-azure-account-key" }
          CORS_ENABLED                 = { value = "true" }
          CORS_ORIGIN                  = { value = "true" }
          CACHE_ENABLED                = { value = "true" }
          CACHE_AUTO_PURGE             = { value = "true" }
          CACHE_TTL                    = { value = "5m" }
          RATE_LIMITER_ENABLED         = { value = "true" }
          RATE_LIMITER_POINTS          = { value = "50" }
          RATE_LIMITER_DURATION        = { value = "1" }
          RATE_LIMITER_STORE           = { value = "memory" }
          LOG_LEVEL                    = { value = "info" }
          MAX_PAYLOAD_SIZE             = { value = "10mb" }
          TELEMETRY                    = { value = "false" }
        }
        content {
          name        = env.key
          value       = try(env.value.value, null)
          secret_name = try(env.value.secret, null)
        }
      }
    }
  }
}

# ──────────────────────────────────────────────
#  Website (Next.js)
# ──────────────────────────────────────────────

resource "azurerm_container_app" "website" {
  name                         = "ca-website-${var.environment}"
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  workload_profile_name        = "Consumption"

  identity {
    type = "SystemAssigned"
  }

  secret {
    name  = "ghcr-password"
    value = var.ghcr_password
  }

  secret {
    name  = "directus-token"
    value = var.directus_token
  }

  registry {
    server               = "ghcr.io"
    username             = var.ghcr_username
    password_secret_name = "ghcr-password"
  }

  ingress {
    external_enabled = true
    target_port      = 3000
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  template {
    min_replicas = 1

    container {
      name   = "ca-website-${var.environment}"
      image  = var.website_image
      cpu    = 0.5
      memory = "1Gi"

      dynamic "env" {
        for_each = {
          DIRECTUS_URL   = { value = "http://${azurerm_container_app.cms.name}" }
          DIRECTUS_TOKEN = { secret = "directus-token" }
        }
        content {
          name        = env.key
          value       = try(env.value.value, null)
          secret_name = try(env.value.secret, null)
        }
      }

      liveness_probe {
        transport     = "TCP"
        port          = 3000
        initial_delay = 0
        timeout       = 5
      }

      readiness_probe {
        transport               = "TCP"
        port                    = 3000
        interval_seconds        = 5
        timeout                 = 5
        failure_count_threshold = 48
        success_count_threshold = 1
      }

      startup_probe {
        transport               = "TCP"
        port                    = 3000
        failure_count_threshold = 240
        interval_seconds        = 1
        timeout                 = 3
        initial_delay           = 1
      }
    }
  }
}
