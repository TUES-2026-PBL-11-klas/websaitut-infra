variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tenant_id" {
  type = string
}

variable "subnet_id" {
  type        = string
  description = "Subnet for the private endpoint"
}

variable "private_dns_zone_id" {
  type        = string
  description = "Shared privatelink.vaultcore.azure.net zone ID (from the networking module)"
}

variable "principal_ids" {
  type        = map(string)
  description = "Map of label => principal_id granted Key Vault Secrets User"
}

variable "tags" {
  type    = map(string)
  default = {}
}
