variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "infrastructure_subnet_id" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
