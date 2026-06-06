resource "azurerm_storage_account" "media" {
  name                            = "mediaelsys"
  location                        = azurerm_resource_group.main.location
  resource_group_name             = azurerm_resource_group.main.name
  account_tier                    = "Standard"
  account_replication_type        = "ZRS"
  allow_nested_items_to_be_public = false

  tags = merge(local.common_tags, { environment = "shared" })
}

resource "azurerm_storage_container" "media" {
  for_each           = local.environments
  name               = "media-${each.key}"
  storage_account_id = azurerm_storage_account.media.id
}
