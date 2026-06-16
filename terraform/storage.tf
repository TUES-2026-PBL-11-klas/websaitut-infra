resource "azurerm_storage_container" "media" {
  for_each           = local.environments
  name               = "media-${each.key}"
  storage_account_id = module.storage.account_id
}
