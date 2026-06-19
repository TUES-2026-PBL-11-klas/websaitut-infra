module "key_vault_shared" {
  source              = "./modules/key_vault"
  name                = "kv-elsys-shared"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id
  subnet_id           = module.networking.endpoints_subnet_id
  private_dns_zone_id = module.networking.key_vault_private_dns_zone_id

  # Every app identity gets read access to shared secrets (ghcr token,
  # storage account key, pg admin password bootstrap, etc.)
  principal_ids = merge(
    { for k, v in azurerm_user_assigned_identity.cms : "cms-${k}" => v.principal_id },
    { for k, v in azurerm_user_assigned_identity.website : "website-${k}" => v.principal_id },
  )

  tags = merge(local.common_tags, { environment = "shared" })
}

module "key_vault_env" {
  source   = "./modules/key_vault"
  for_each = local.cms_per_env

  name                = "kv-elsys-${each.key}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id
  subnet_id           = module.networking.endpoints_subnet_id
  private_dns_zone_id = module.networking.key_vault_private_dns_zone_id

  principal_ids = {
    cms = azurerm_user_assigned_identity.cms[each.key].principal_id
  }

  tags = merge(local.common_tags, { environment = each.key })
}
