resource "azurerm_postgresql_flexible_server_database" "directus" {
  for_each  = local.environments
  name      = "directus-${each.key}"
  server_id = module.database.server_id
}
