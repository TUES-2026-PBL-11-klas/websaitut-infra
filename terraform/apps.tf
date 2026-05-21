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

  secret {
    name                = "admin-password"
    identity            = "System"
    key_vault_secret_id = azurerm_key_vault_secret.directus_admin_password.versionless_id
  }

  secret {
    name                = "db-password"
    identity            = "System"
    key_vault_secret_id = azurerm_key_vault_secret.directus_db_password.versionless_id
  }

  secret {
    name                = "crypto-key"
    identity            = "System"
    key_vault_secret_id = azurerm_key_vault_secret.directus_key.versionless_id
  }

  secret {
    name                = "crypto-secret"
    identity            = "System"
    key_vault_secret_id = azurerm_key_vault_secret.directus_secret.versionless_id
  }

  secret {
    name                = "storage-key"
    identity            = "System"
    key_vault_secret_id = azurerm_key_vault_secret.storage_account_key.versionless_id
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

      # Database
      env {
        name  = "DB_CLIENT"
        value = "pg"
      }
      env {
        name  = "DB_HOST"
        value = azurerm_postgresql_flexible_server.main.fqdn
      }
      env {
        name  = "DB_PORT"
        value = "5432"
      }
      env {
        name  = "DB_DATABASE"
        value = "directus"
      }
      env {
        name  = "DB_USER"
        value = "directus"
      }
      env {
        name  = "DB_SSL"
        value = "true"
      }
      env {
        name        = "DB_PASSWORD"
        secret_name = "db-password"
      }

      # Auth
      env {
        name  = "ADMIN_EMAIL"
        value = var.directus_admin_email
      }
      env {
        name        = "ADMIN_PASSWORD"
        secret_name = "admin-password"
      }
      env {
        name        = "KEY"
        secret_name = "crypto-key"
      }
      env {
        name        = "SECRET"
        secret_name = "crypto-secret"
      }
      # Public URL
      env {
        name  = "PUBLIC_URL"
        value = var.directus_public_url
      }

      # Storage
      env {
        name  = "STORAGE_LOCATIONS"
        value = "azure"
      }
      env {
        name  = "STORAGE_AZURE_DRIVER"
        value = "azure"
      }
      env {
        name  = "STORAGE_AZURE_CONTAINER_NAME"
        value = "media"
      }
      env {
        name  = "STORAGE_AZURE_ACCOUNT_NAME"
        value = azurerm_storage_account.media.name
      }
      env {
        name        = "STORAGE_AZURE_ACCOUNT_KEY"
        secret_name = "storage-key"
      }

      # Misc
      env {
        name  = "CORS_ENABLED"
        value = "true"
      }
      env {
        name  = "CORS_ORIGIN"
        value = "true"
      }
      env {
        name  = "CACHE_ENABLED"
        value = "true"
      }
      env {
        name  = "CACHE_AUTO_PURGE"
        value = "true"
      }
      env {
        name  = "CACHE_TTL"
        value = "5m"
      }
      env {
        name  = "RATE_LIMITER_ENABLED"
        value = "true"
      }
      env {
        name  = "RATE_LIMITER_POINTS"
        value = "50"
      }
      env {
        name  = "RATE_LIMITER_DURATION"
        value = "1"
      }
      env {
        name  = "RATE_LIMITER_STORE"
        value = "memory"
      }
      env {
        name  = "LOG_LEVEL"
        value = "info"
      }
      env {
        name  = "MAX_PAYLOAD_SIZE"
        value = "10mb"
      }
      env {
        name  = "TELEMETRY"
        value = "false"
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
    container {
      name   = "ca-website-${var.environment}"
      image  = var.website_image
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "DIRECTUS_URL"
        value = "http://${azurerm_container_app.cms.name}"
      }
      env {
        name        = "DIRECTUS_TOKEN"
        secret_name = "directus-token"
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
