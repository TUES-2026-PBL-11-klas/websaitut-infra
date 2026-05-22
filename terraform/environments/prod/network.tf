# ──────────────────────────────────────────────
#  VNet & Subnets
# ──────────────────────────────────────────────

resource "azurerm_virtual_network" "main" {
  name                = "vnet-elsys-${var.environment}"
  location            = var.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = ["10.0.0.0/20"]
}

resource "azurerm_subnet" "postgres" {
  name                            = "snet-postgres"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = ["10.0.0.0/28"]
  default_outbound_access_enabled = false
  service_endpoints               = ["Microsoft.Storage"]

  delegation {
    name = "dlg-Microsoft.DBforPostgreSQL-flexibleServers"
    service_delegation {
      name    = "Microsoft.DBforPostgreSQL/flexibleServers"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "apps" {
  name                            = "snet-apps"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = ["10.0.2.0/23"]
  default_outbound_access_enabled = false

  delegation {
    name = "Microsoft.App.environments"
    service_delegation {
      name    = "Microsoft.App/environments"
      actions = ["Microsoft.Network/virtualNetworks/subnets/join/action"]
    }
  }
}

resource "azurerm_subnet" "endpoints" {
  name                            = "snet-endpoints"
  resource_group_name             = azurerm_resource_group.main.name
  virtual_network_name            = azurerm_virtual_network.main.name
  address_prefixes                = ["10.0.4.0/28"]
  default_outbound_access_enabled = false
}
