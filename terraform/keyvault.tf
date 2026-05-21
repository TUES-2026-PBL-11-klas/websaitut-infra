# ──────────────────────────────────────────────
#  Key Vault (CMS) + Private Endpoint
# ──────────────────────────────────────────────

data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                = "kv-elsys-cms-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id

  # Allow Terraform itself to manage secrets
  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# Separate resource to break the cycle: KV -> secrets -> CMS -> KV
resource "azurerm_key_vault_access_policy" "cms" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_container_app.cms.identity[0].principal_id

  secret_permissions = ["Get"]
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
    private_connection_resource_id = azurerm_key_vault.main.id
    is_manual_connection           = false
    subresource_names              = ["vault"]
  }

  private_dns_zone_group {
    name                 = "vault-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.vault.id]
  }
}

# --- CMS Secrets ---

locals {
  secret_tags = {
    "file-encoding" = "utf-8"
  }
}

resource "azurerm_key_vault_secret" "directus_admin_password" {
  name         = "directus-admin-password"
  value        = var.directus_admin_password
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.secret_tags
}

resource "azurerm_key_vault_secret" "directus_db_password" {
  name         = "directus-db-password"
  value        = var.directus_db_password
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.secret_tags
}

resource "azurerm_key_vault_secret" "directus_key" {
  name         = "directus-key"
  value        = var.directus_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.secret_tags
}

resource "azurerm_key_vault_secret" "directus_secret" {
  name         = "directus-secret"
  value        = var.directus_secret
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.secret_tags
}

resource "azurerm_key_vault_secret" "storage_account_key" {
  name         = "storage-account-key"
  value        = var.storage_account_key
  key_vault_id = azurerm_key_vault.main.id
  tags         = local.secret_tags
}

# ──────────────────────────────────────────────
#  Key Vault (Website)
# ──────────────────────────────────────────────

resource "azurerm_key_vault" "website" {
  name                = "kv-elsys-website-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "standard"
  tenant_id           = var.tenant_id

  access_policy {
    tenant_id = var.tenant_id
    object_id = data.azurerm_client_config.current.object_id

    secret_permissions = ["Get", "List", "Set", "Delete", "Purge"]
  }
}

# Separate resource to break the cycle: KV -> secrets -> website -> KV
resource "azurerm_key_vault_access_policy" "website" {
  key_vault_id = azurerm_key_vault.website.id
  tenant_id    = var.tenant_id
  object_id    = azurerm_container_app.website.identity[0].principal_id

  secret_permissions = ["Get"]
}

resource "azurerm_key_vault_secret" "directus_token" {
  name         = "directus-token"
  value        = var.directus_token
  key_vault_id = azurerm_key_vault.website.id
  tags         = local.secret_tags
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
