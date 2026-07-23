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

