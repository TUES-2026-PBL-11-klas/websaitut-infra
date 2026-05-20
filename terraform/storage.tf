# ──────────────────────────────────────────────
#  Storage Account (Directus media)
# ──────────────────────────────────────────────

resource "azurerm_storage_account" "media" {
  name                            = "mediaelsys"
  location                        = var.location
  resource_group_name             = azurerm_resource_group.main.name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false
}

resource "azurerm_storage_container" "media" {
  name               = "media"
  storage_account_id = azurerm_storage_account.media.id
}
