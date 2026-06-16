module "cms" {
  source = "../container_app"

  name                         = "ca-cms-${var.environment}"
  resource_group_name          = var.resource_group_name
  container_app_environment_id = var.container_app_environment_id
  identity_id                  = azurerm_user_assigned_identity.cms.id
  image                        = var.cms_image
  port                         = 8055
  min_replicas                 = var.app_config.min_replicas
  cpu                          = var.app_config.cpu
  memory                       = var.app_config.memory

  secrets = {
    "admin-password"            = data.azurerm_key_vault_secret.directus_admin_password.versionless_id
    "db-password"               = data.azurerm_key_vault_secret.directus_db_password.versionless_id
    "key"                       = data.azurerm_key_vault_secret.directus_key.versionless_id
    "secret"                    = data.azurerm_key_vault_secret.directus_secret.versionless_id
    "storage-azure-account-key" = var.storage_account_key_secret_id
  }

  plain_env = {
    DB_CLIENT                    = "pg"
    DB_HOST                      = var.postgres_server_fqdn
    DB_PORT                      = "5432"
    DB_DATABASE                  = "directus-${var.environment}"
    DB_USER                      = "directus"
    DB_SSL                       = "true"
    ADMIN_EMAIL                  = var.directus_admin_email
    PUBLIC_URL                   = "https://ca-cms-${var.environment}.${var.container_app_environment_default_domain}"
    STORAGE_LOCATIONS            = "azure"
    STORAGE_AZURE_DRIVER         = "azure"
    STORAGE_AZURE_CONTAINER_NAME = "media-${var.environment}"
    STORAGE_AZURE_ACCOUNT_NAME   = var.storage_account_name
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

  secret_env = {
    DB_PASSWORD               = "db-password"
    ADMIN_PASSWORD            = "admin-password"
    KEY                       = "key"
    SECRET                    = "secret"
    STORAGE_AZURE_ACCOUNT_KEY = "storage-azure-account-key"
  }

  tags = var.tags
}
