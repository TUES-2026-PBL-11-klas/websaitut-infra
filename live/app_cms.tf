locals {
  cms_per_env = {
    staging = { min_replicas = 0, domain = "directus.staging.elsys.website" }
    prod    = { min_replicas = 1, domain = "directus.elsys.website" }
  }

  secret_names = {
    "admin-password" = "directus-admin-password"
    "db-password"    = "directus-db-password"
    "key"            = "directus-key"
    "secret"         = "directus-secret"
  }
}

resource "azurerm_user_assigned_identity" "cms" {
  for_each            = local.cms_per_env
  name                = "id-cms-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(local.common_tags, { environment = each.key })
}

resource "azurerm_postgresql_flexible_server_database" "cms" {
  for_each  = local.cms_per_env
  name      = "directus-${each.key}"
  server_id = module.database.server_id
}

resource "azurerm_storage_container" "media" {
  for_each           = local.cms_per_env
  name               = "media-${each.key}"
  storage_account_id = azurerm_storage_account.media.id
}

module "cms" {
  source   = "./modules/container_app"
  for_each = local.cms_per_env

  name                         = "ca-cms-${each.key}"
  resource_group_name          = azurerm_resource_group.main.name
  container_app_environment_id = azurerm_container_app_environment.main.id
  identity_id                  = azurerm_user_assigned_identity.cms[each.key].id
  image                        = var.directus_image
  port                         = 8055
  min_replicas                 = each.value.min_replicas
  custom_domains               = [each.value.domain]

  plain_env = {
    DB_CLIENT   = "pg"
    DB_HOST     = module.database.server_fqdn
    DB_PORT     = "5432"
    DB_DATABASE = azurerm_postgresql_flexible_server_database.cms[each.key].name
    DB_USER     = "directus"
    DB_SSL      = "true"
    ADMIN_EMAIL = var.directus_admin_email
    # Directus generates asset URLs and auth redirects from PUBLIC_URL — it
    # must match the custom domain, not the *.azurecontainerapps.io FQDN.
    PUBLIC_URL                   = "https://${each.value.domain}"
    STORAGE_LOCATIONS            = "azure"
    STORAGE_AZURE_DRIVER         = "azure"
    STORAGE_AZURE_CONTAINER_NAME = azurerm_storage_container.media[each.key].name
    STORAGE_AZURE_ACCOUNT_NAME   = azurerm_storage_account.media.name
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

  # Reference secrets by constructed URI (control-plane attribute, no
  # data-plane read) so TF never touches the vault firewall. The container
  # app resolves the value at runtime via its UAMI. versionless_id == a
  # trailing-slash vault_uri + "secrets/<name>".
  secrets = merge(
    {
      for logical, kv_name in local.secret_names :
      logical => "${module.key_vault_env[each.key].vault_uri}secrets/${kv_name}"
    },
    {
      "storage-azure-account-key" = "${module.key_vault_shared.vault_uri}secrets/storage-account-key"
    }
  )

  secret_env = {
    DB_PASSWORD               = "db-password"
    ADMIN_PASSWORD            = "admin-password"
    KEY                       = "key"
    SECRET                    = "secret"
    STORAGE_AZURE_ACCOUNT_KEY = "storage-azure-account-key"
  }

  tags = merge(local.common_tags, { environment = each.key, app = "cms" })
}
