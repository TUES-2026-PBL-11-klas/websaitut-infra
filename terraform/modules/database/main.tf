resource "azurerm_private_dns_zone" "this" {
  name                = "pg-elsys.private.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "this" {
  name                  = "pdnslink-pg"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.this.name
  virtual_network_id    = var.vnet_id
}

resource "azurerm_postgresql_flexible_server" "this" {
  name                = "pg-elsys"
  location            = var.location
  resource_group_name = var.resource_group_name

  version                       = "17"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  zone                          = "1"
  backup_retention_days         = 14
  auto_grow_enabled             = true
  public_network_access_enabled = false

  delegated_subnet_id = var.delegated_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.this.id

  administrator_login    = var.admin_login
  administrator_password = var.admin_password

  authentication {
    password_auth_enabled = true
  }

  tags = var.tags

  depends_on = [azurerm_private_dns_zone_virtual_network_link.this]
}
