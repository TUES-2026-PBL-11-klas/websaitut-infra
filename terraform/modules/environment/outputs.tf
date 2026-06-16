output "cms_fqdn" {
  value = module.cms.fqdn
}

output "website_fqdn" {
  value = module.website.fqdn
}

output "cms_identity_principal_id" {
  value = azurerm_user_assigned_identity.cms.principal_id
}

output "website_identity_principal_id" {
  value = azurerm_user_assigned_identity.website.principal_id
}
