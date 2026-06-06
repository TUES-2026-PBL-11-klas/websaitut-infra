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

variable "vnet_id" {
  type        = string
  description = "VNet for the private DNS zone link"
}

variable "principal_ids" {
  type        = map(string)
  description = "Map of label => principal_id granted Key Vault Secrets User"
}

variable "secrets" {
  type        = map(string)
  default     = {}
  description = "Secrets whose value is fully managed by Terraform"
}

variable "placeholder_secrets" {
  type        = map(string)
  default     = {}
  description = "Secrets seeded with an initial value; manual updates are never overwritten"
}

variable "tags" {
  type    = map(string)
  default = {}
}
