data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "this" {
  name                          = var.name
  location                      = var.location
  resource_group_name           = var.resource_group_name
  sku_name                      = "standard"
  tenant_id                     = var.tenant_id
  rbac_authorization_enabled    = true
  public_network_access_enabled = true
  soft_delete_retention_days    = 7
  purge_protection_enabled      = false

  tags = var.tags
}

resource "azurerm_role_assignment" "admin" {
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Administrator"
  principal_id         = data.azurerm_client_config.current.object_id
}

resource "azurerm_role_assignment" "secrets_user" {
  for_each             = var.principal_ids
  scope                = azurerm_key_vault.this.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = each.value
}

resource "time_sleep" "rbac" {
  depends_on      = [azurerm_role_assignment.admin, azurerm_role_assignment.secrets_user]
  create_duration = "60s"
}

resource "azurerm_private_dns_zone" "this" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "pdnslink-kv"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_private_endpoint" "this" {
  name                = "pe-${var.name}"
  location            = var.location
  resource_group_name = var.resource_group_name
  subnet_id           = var.subnet_id

  private_service_connection {
    name                           = "psc-${var.name}"
    private_connection_resource_id = azurerm_key_vault.this.id
    subresource_names              = ["vault"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "kv-dns"
    private_dns_zone_ids = [azurerm_private_dns_zone.this.id]
  }
}
