# ──────────────────────────────────────────────
#  Key Vault shared config
# ──────────────────────────────────────────────

data "azurerm_client_config" "current" {}

# ──────────────────────────────────────────────
#  User-Assigned Managed Identities
# ──────────────────────────────────────────────

resource "azurerm_user_assigned_identity" "cms" {
  name                = "id-cms-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_user_assigned_identity" "website" {
  name                = "id-website-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
}

# ──────────────────────────────────────────────
#  CMS Key Vault (RBAC authorization)
# ──────────────────────────────────────────────

resource "azurerm_key_vault" "cms" {
  name                       = "kv-elsys-cms-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  sku_name                   = "standard"
  tenant_id                  = var.tenant_id
  rbac_authorization_enabled = true
}

# Terraform operator — full secrets management
resource "azurerm_role_assignment" "cms_kv_terraform" {
  scope                = azurerm_key_vault.cms.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# CMS container app — read-only secrets access
resource "azurerm_role_assignment" "cms_kv_identity" {
  scope                = azurerm_key_vault.cms.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.cms.principal_id
}

# --- Shared Private DNS zone for all Key Vaults ---

resource "azurerm_private_dns_zone" "vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "vault" {
  name                  = "pdnslink-vault"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.vault.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_private_endpoint" "vault_cms" {
  name                = "pe-vault-cms"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-vault-cms"
    private_connection_resource_id = azurerm_key_vault.cms.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "vault-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

# --- CMS Secrets ---
# Values are bootstrapped manually — see terraform/bootstrap/README.md.
# storage-account-key is the exception: Terraform owns it.

locals {
  secret_tags = {
    "file-encoding" = "utf-8"
  }
}

data "azurerm_key_vault_secret" "directus_admin_password" {
  name         = "directus-admin-password"
  key_vault_id = azurerm_key_vault.cms.id
  depends_on   = [azurerm_role_assignment.cms_kv_terraform]
}

data "azurerm_key_vault_secret" "directus_db_password" {
  name         = "directus-db-password"
  key_vault_id = azurerm_key_vault.cms.id
  depends_on   = [azurerm_role_assignment.cms_kv_terraform]
}

data "azurerm_key_vault_secret" "directus_key" {
  name         = "directus-key"
  key_vault_id = azurerm_key_vault.cms.id
  depends_on   = [azurerm_role_assignment.cms_kv_terraform]
}

data "azurerm_key_vault_secret" "directus_secret" {
  name         = "directus-secret"
  key_vault_id = azurerm_key_vault.cms.id
  depends_on   = [azurerm_role_assignment.cms_kv_terraform]
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = azurerm_storage_account.media.primary_access_key
  key_vault_id = azurerm_key_vault.cms.id
  tags         = local.secret_tags
  depends_on   = [azurerm_role_assignment.cms_kv_terraform]
}

# ──────────────────────────────────────────────
#  Website Key Vault (RBAC authorization)
# ──────────────────────────────────────────────

resource "azurerm_key_vault" "website" {
  name                       = "kv-elsys-website-${var.environment}"
  location                   = var.location
  resource_group_name        = azurerm_resource_group.main.name
  sku_name                   = "standard"
  tenant_id                  = var.tenant_id
  rbac_authorization_enabled = true
}

# Terraform operator — full secrets management
resource "azurerm_role_assignment" "website_kv_terraform" {
  scope                = azurerm_key_vault.website.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

# Website container app — read-only secrets access
resource "azurerm_role_assignment" "website_kv_identity" {
  scope                = azurerm_key_vault.website.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.website.principal_id
}

data "azurerm_key_vault_secret" "directus_token" {
  name         = "directus-token"
  key_vault_id = azurerm_key_vault.website.id
  depends_on   = [azurerm_role_assignment.website_kv_terraform]
}

data "azurerm_key_vault_secret" "ghcr_password" {
  name         = "ghcr-password"
  key_vault_id = azurerm_key_vault.website.id
  depends_on   = [azurerm_role_assignment.website_kv_terraform]
}

resource "azurerm_private_endpoint" "vault_website" {
  name                = "pe-vault-website"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  subnet_id           = azurerm_subnet.endpoints.id

  private_service_connection {
    name                           = "psc-vault-website"
    private_connection_resource_id = azurerm_key_vault.website.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "vault-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}
