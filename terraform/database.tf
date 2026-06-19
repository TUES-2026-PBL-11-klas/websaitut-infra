data "azurerm_key_vault_secret" "pg_admin_password" {
  name         = "pg-admin-password"
  key_vault_id = module.key_vault_shared.id
}

module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  delegated_subnet_id = module.networking.postgres_subnet_id
  vnet_id             = module.networking.vnet_id
  admin_login         = "elsys_pgadmin"
  admin_password      = data.azurerm_key_vault_secret.pg_admin_password.value
  tags                = merge(local.common_tags, { environment = "shared" })
}
