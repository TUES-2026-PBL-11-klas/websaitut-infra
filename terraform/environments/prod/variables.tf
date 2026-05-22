variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "location" {
  type    = string
  default = "polandcentral"
}

variable "environment" {
  type    = string
  default = "prod"
}

variable "directus_admin_email" {
  type        = string
  description = "Directus admin email"
}

variable "directus_public_url" {
  type        = string
  description = "Public URL for Directus CMS"
}

variable "directus_image" {
  type    = string
  default = "docker.io/directus/directus:11.17.2"
}

variable "website_image" {
  type        = string
  description = "Full ghcr.io image:tag for the website"
}

variable "ghcr_username" {
  type    = string
  default = "rangelovkiril"
}
