resource "azurerm_resource_group" "main" {
  name     = "rg-website"
  location = var.location
  tags     = merge(local.common_tags, { environment = "shared" })
}

locals {
  common_tags = {
    project    = "website"
    managed_by = "terraform"
  }
}
