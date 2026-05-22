# ──────────────────────────────────────────────
#  Resource Group
# ──────────────────────────────────────────────
resource "azurerm_resource_group" "main" {
  name     = "rg-website-${var.environment}"
  location = "germanywestcentral"
}
