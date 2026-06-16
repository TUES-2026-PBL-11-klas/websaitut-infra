variable "environment" {
  type = string
  validation {
    condition     = contains(["staging", "prod"], var.environment)
    error_message = "environment must be 'staging' or 'prod'."
  }
}

variable "resource_group_name" {
  type = string
}

variable "location" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "postgres_server_id" {
  type = string
}

variable "postgres_server_fqdn" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "container_app_environment_default_domain" {
  type = string
}

variable "storage_account_id" {
  type = string
}

variable "storage_account_name" {
  type = string
}

variable "key_vault_id" {
  type = string
}

variable "app_config" {
  type = object({
    min_replicas = number
    cpu          = number
    memory       = string
  })
}

variable "cms_image" {
  type = string
}

variable "website_image" {
  type = string
}

variable "directus_admin_email" {
  type = string
}

variable "ghcr_username" {
  type = string
}

variable "ghcr_password_secret_id" {
  type = string
}

variable "storage_account_key_secret_id" {
  type = string
}
