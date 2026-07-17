locals {
  # CAE egress IP is the only steady-state entry; extra IPs are for
  # out-of-band secret rotation. Empty list => firewall stays open.
  kv_allowed_ips = var.kv_firewall_enabled ? concat(
    [azurerm_container_app_environment.main.static_ip_address],
    var.kv_extra_allowed_ips,
  ) : []
}

module "key_vault_shared" {
  source              = "./modules/key_vault"
  name                = "kv-elsys-shared"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  tenant_id           = var.tenant_id
  allowed_ips         = local.kv_allowed_ips

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
  allowed_ips         = local.kv_allowed_ips

  principal_ids = {
    cms = azurerm_user_assigned_identity.cms[each.key].principal_id
  }

  tags = merge(local.common_tags, { environment = each.key })
}
