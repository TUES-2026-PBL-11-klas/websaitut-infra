resource "azurerm_storage_container" "this" {
  name               = "media-${var.environment}"
  storage_account_id = var.storage_account_id
}
