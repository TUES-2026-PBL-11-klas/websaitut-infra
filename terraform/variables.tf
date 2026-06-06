variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "location" {
  type        = string
  default     = "polandcentral"
  description = "Azure region"
}

variable "directus_image" {
  type        = string
  default     = "directus/directus:11.17.2"
  description = "Directus container image"
}

variable "images" {
  type        = map(string)
  description = "Per-env website image, keys: staging, prod"
}

variable "ghcr_username" {
  type        = string
  default     = "rangelovkiril"
  description = "GHCR registry username"
}

variable "directus_admin_email" {
  type        = string
  description = "Directus admin email"
}

variable "ghcr_password" {
  type        = string
  sensitive   = true
  description = "GitHub PAT for GHCR pull"
}

variable "prod_directus_admin_password" {
  type        = string
  sensitive   = true
  description = "Directus admin password (prod)"
}

variable "prod_directus_key" {
  type        = string
  sensitive   = true
  description = "Directus KEY (prod)"
}

variable "prod_directus_secret" {
  type        = string
  sensitive   = true
  description = "Directus SECRET (prod)"
}

variable "prod_directus_db_password" {
  type        = string
  sensitive   = true
  description = "PG directus user password (prod)"
}

variable "directus_public_urls" {
  type        = map(string)
  description = "Public URLs for Directus CMS per environment (fill in after first apply)"
  default = {
    staging = ""
    prod    = ""
  }
}
