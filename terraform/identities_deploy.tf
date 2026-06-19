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

resource "azurerm_role_assignment" "deploy_contributor" {
  for_each             = local.deploy_envs
  scope                = azurerm_resource_group.main.id
  role_definition_name = "Contributor"
  principal_id         = azurerm_user_assigned_identity.deploy[each.key].principal_id
}

variable "github_repo" {
  type        = string
  description = "GitHub repository in org/repo format for OIDC federation"
  default     = "TUES-2026-PBL-11-klas/websaitut"
}
