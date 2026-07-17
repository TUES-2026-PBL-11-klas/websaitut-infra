module "database" {
  source              = "./modules/database"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  delegated_subnet_id = module.networking.postgres_subnet_id
  vnet_id             = module.networking.vnet_id
  admin_login         = "elsys_pgadmin"
  admin_password      = var.pg_admin_password
  tags                = merge(local.common_tags, { environment = "shared" })
}
