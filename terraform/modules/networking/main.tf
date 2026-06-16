resource "azurerm_virtual_network" "this" {
  name                = "vnet-website"
  location            = var.location
  resource_group_name = var.resource_group_name
  address_space       = ["10.0.0.0/20"]

  tags = var.tags
}

resource "azurerm_subnet" "apps" {
  name                 = "snet-apps"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.2.0/23"]

  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.App-environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "postgres" {
  name                 = "snet-postgres"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/28"]

  service_endpoints               = ["Microsoft.Storage"]
  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.DBforPostgreSQL-flexibleServers"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "endpoints" {
  name                 = "snet-endpoints"
  resource_group_name  = var.resource_group_name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.4.0/28"]

  default_outbound_access_enabled = false
}

# Shared zone: every Key Vault instance's private endpoint links here,
# so it must live in a singleton module, not inside key_vault itself.
resource "azurerm_private_dns_zone" "key_vault" {
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = var.resource_group_name
}

resource "azurerm_private_dns_zone_virtual_network_link" "key_vault" {
  name                  = "pdnslink-kv"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.key_vault.name
  virtual_network_id    = azurerm_virtual_network.this.id
}
