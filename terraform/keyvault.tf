resource "azurerm_key_vault" "main" {
  name                          = "kv-elsys-website"
  location                      = azurerm_resource_group.main.location
  resource_group_name           = azurerm_resource_group.main.name
  sku_name                      = "standard"
  tenant_id                     = var.tenant_id
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false

  tags = merge(local.common_tags, { environment = "shared" })
}

resource "azurerm_user_assigned_identity" "app" {
  for_each            = toset(["cms-staging", "cms-prod", "website-staging", "website-prod"])
  name                = "id-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  tags = merge(local.common_tags, {
    environment = split("-", each.key)[length(split("-", each.key)) - 1]
  })
}

resource "azurerm_role_assignment" "kv_admin" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "kv_secrets_user" {
  for_each             = toset(["cms-staging", "cms-prod", "website-staging", "website-prod"])
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.app[each.key].principal_id
}

resource "time_sleep" "wait_for_kv_rbac" {
  depends_on      = [azurerm_role_assignment.kv_admin, azurerm_role_assignment.kv_secrets_user]
  create_duration = "60s"
}

resource "azurerm_private_dns_zone" "keyvault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "keyvault" {
  name                  = "pdnslink-kv"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.keyvault.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_endpoint" "keyvault" {
  name                = "pe-kv-website"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-kv-website"
    private_connection_resource_id = azurerm_key_vault.main.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.keyvault.id]
  }
}

# --- Secrets: staging (auto-generated) ---

resource "azurerm_key_vault_secret" "staging" {
  for_each     = toset(["directus-admin-password", "directus-key", "directus-secret", "directus-db-password"])
  name         = "staging-${each.key}"
  value        = random_password.staging[each.key].result
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_kv_rbac]
}

# --- Secrets: prod + shared (variables + computed) ---

locals {
  kv_secrets_shared = {
    "prod-directus-admin-password" = var.prod_directus_admin_password
    "prod-directus-key"            = var.prod_directus_key
    "prod-directus-secret"         = var.prod_directus_secret
    "prod-directus-db-password"    = var.prod_directus_db_password
    "pg-admin-password"            = random_password.pg_admin.result
    "ghcr-password"                = var.ghcr_password
    "storage-account-key"          = azurerm_storage_account.media.primary_access_key
  }
}

resource "azurerm_key_vault_secret" "shared" {
  for_each     = local.kv_secrets_shared
  name         = each.key
  value        = each.value
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_kv_rbac]
}

# --- Secrets: Directus API tokens (placeholder, updated manually) ---

resource "azurerm_key_vault_secret" "token" {
  for_each     = local.environments
  name         = "${each.key}-directus-token"
  value        = "placeholder"
  key_vault_id = azurerm_key_vault.main.id
  depends_on   = [time_sleep.wait_for_kv_rbac]

  lifecycle {
    ignore_changes = [value]
  }
}

# --- Secret ID lookup maps (consumed by cms.tf and website.tf) ---

locals {
  cms_secret_ids = {
    staging = {
      "admin-password"            = azurerm_key_vault_secret.staging["directus-admin-password"].versionless_id
      "db-password"               = azurerm_key_vault_secret.staging["directus-db-password"].versionless_id
      "key"                       = azurerm_key_vault_secret.staging["directus-key"].versionless_id
      "secret"                    = azurerm_key_vault_secret.staging["directus-secret"].versionless_id
      "storage-azure-account-key" = azurerm_key_vault_secret.shared["storage-account-key"].versionless_id
    }
    prod = {
      "admin-password"            = azurerm_key_vault_secret.shared["prod-directus-admin-password"].versionless_id
      "db-password"               = azurerm_key_vault_secret.shared["prod-directus-db-password"].versionless_id
      "key"                       = azurerm_key_vault_secret.shared["prod-directus-key"].versionless_id
      "secret"                    = azurerm_key_vault_secret.shared["prod-directus-secret"].versionless_id
      "storage-azure-account-key" = azurerm_key_vault_secret.shared["storage-account-key"].versionless_id
    }
  }

  website_secret_ids = {
    staging = {
      "ghcr-password"  = azurerm_key_vault_secret.shared["ghcr-password"].versionless_id
      "directus-token" = azurerm_key_vault_secret.token["staging"].versionless_id
    }
    prod = {
      "ghcr-password"  = azurerm_key_vault_secret.shared["ghcr-password"].versionless_id
      "directus-token" = azurerm_key_vault_secret.token["prod"].versionless_id
    }
  }
}
