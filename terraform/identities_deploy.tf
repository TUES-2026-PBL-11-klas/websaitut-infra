locals {
  deploy_envs = {
    staging = "staging"
    prod    = "production"
  }
}

resource "azurerm_user_assigned_identity" "deploy" {
  for_each            = local.deploy_envs
  name                = "id-deploy-${each.key}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = merge(local.common_tags, { purpose = "cd", environment = each.key })
}

resource "azurerm_federated_identity_credential" "github_actions" {
  for_each                  = local.deploy_envs
  name                      = "gh-actions-${each.key}"
  user_assigned_identity_id = azurerm_user_assigned_identity.deploy[each.key].id
  audience                  = ["api://AzureADTokenExchange"]
  issuer                    = "https://token.actions.githubusercontent.com"
  subject                   = "repo:${var.github_repo}:environment:${each.value}"
}

# CI/CD only runs `az containerapp update --image`, so each deploy identity
# gets Container Apps Contributor scoped to its own env's two apps — staging
# can't touch prod, and nobody gets near KV/DB/storage.
resource "azurerm_role_assignment" "deploy_website" {
  for_each             = local.deploy_envs
  scope                = module.website[each.key].id
  role_definition_name = "Container Apps Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
}

resource "azurerm_role_assignment" "deploy_cms" {
  for_each             = local.deploy_envs
  scope                = module.cms[each.key].id
  role_definition_name = "Container Apps Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in org/repo format for OIDC federation"
  default     = "TUES-2026-PBL-11-klas/websaitut"
}
