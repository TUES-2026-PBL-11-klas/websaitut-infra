resource "azurerm_storage_account" "this" {
  name                            = "mediaelsys"
  location                        = var.location
  resource_group_name             = var.resource_group_name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false

  tags = var.tags
}
