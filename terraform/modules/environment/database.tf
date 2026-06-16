resource "azurerm_postgresql_flexible_server_database" "this" {
  name      = "directus-${var.environment}"
  server_id = var.postgres_server_id
}
