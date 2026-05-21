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

# --- Secrets (never commit values) ---

variable "directus_admin_password" {
  type      = string
  sensitive = true
}

variable "directus_db_password" {
  type      = string
  sensitive = true
}

variable "directus_key" {
  type      = string
  sensitive = true
}

variable "directus_secret" {
  type      = string
  sensitive = true
}

variable "directus_token" {
  type      = string
  sensitive = true
}

variable "storage_account_key" {
  type      = string
  sensitive = true
}

variable "ghcr_password" {
  type        = string
  sensitive   = true
  description = "GitHub Container Registry PAT"
}

# --- App config ---

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
