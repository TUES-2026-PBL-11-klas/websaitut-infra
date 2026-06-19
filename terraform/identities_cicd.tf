# NOT used by container apps at runtime — those have per-app identities in app_*.tf.
resource "azurerm_user_assigned_identity" "cicd" {
  for_each            = toset(["github-deploy"])
  name                = "id-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(local.common_tags, { purpose = "cicd" })
}
