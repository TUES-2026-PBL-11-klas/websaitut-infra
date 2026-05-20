# ──────────────────────────────────────────────
#  PostgreSQL Flexible Server
# ──────────────────────────────────────────────

resource "azurerm_private_dns_zone" "postgres" {
  name                = "pg-elsys-${var.environment}.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "rovbeufajknwq"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = azurerm_virtual_network.main.id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                          = "pg-elsys-${var.environment}"
  location                      = var.location
  resource_group_name           = azurerm_resource_group.main.name
  delegated_subnet_id           = azurerm_subnet.postgres.id
  private_dns_zone_id           = azurerm_private_dns_zone.postgres.id
  public_network_access_enabled = false
  auto_grow_enabled             = true
  zone                          = "1"

  authentication {
    password_auth_enabled = true
  }

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "directus" {
  name      = "directus"
  server_id = azurerm_postgresql_flexible_server.main.id
}
