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

variable "principal_ids" {
  type        = map(string)
  description = "Map of label => principal_id granted Key Vault Secrets User"
}

variable "tags" {
  type    = map(string)
  default = {}
}
