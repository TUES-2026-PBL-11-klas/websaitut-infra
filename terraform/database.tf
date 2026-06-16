resource "azurerm_private_dns_zone" "postgres" {
  name                = "pg-elsys.private.postgres.database.azure.com"
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgres" {
  name                  = "pdnslink-pg"
  resource_group_name   = azurerm_resource_group.main.name
  private_dns_zone_name = azurerm_private_dns_zone.postgres.name
  virtual_network_id    = module.networking.vnet_id
}

resource "azurerm_postgresql_flexible_server" "main" {
  name                = "pg-elsys"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name

  version                       = "17"
  sku_name                      = "B_Standard_B1ms"
  storage_mb                    = 32768
  zone                          = "1"
  backup_retention_days         = 14
  auto_grow_enabled             = true
  public_network_access_enabled = false

  delegated_subnet_id = module.networking.postgres_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgres.id

  administrator_login    = "elsys_pgadmin"
  administrator_password = data.azurerm_key_vault_secret.pg_admin_password.value

  authentication {
    password_auth_enabled = true
  }

  tags = merge(local.common_tags, { environment = "shared" })

  depends_on = [azurerm_private_dns_zone_virtual_network_link.postgres]
}

resource "azurerm_postgresql_flexible_server_database" "directus" {
  for_each  = local.environments
  name      = "directus-${each.key}"
  server_id = azurerm_postgresql_flexible_server.main.id
}
