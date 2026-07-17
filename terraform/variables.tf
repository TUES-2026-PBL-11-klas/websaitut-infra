variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "tenant_id" {
  type        = string
  description = "Azure AD tenant ID"
}

variable "pg_admin_password" {
  type        = string
  sensitive   = true
  description = "PostgreSQL admin password. Provide via TF_VAR_pg_admin_password or a gitignored *.secret.tfvars; KV holds the source-of-truth copy. Only consumed on server (re)creation — see ignore_changes in the database module."
}

variable "location" {
  type        = string
  default     = "polandcentral"
  description = "Azure region"
}

variable "directus_image" {
  type        = string
  default     = "directus/directus:11.17.2"
  description = "Initial Directus CMS image. CI/CD updates via az CLI; TF ignores changes after first apply."
}

variable "images" {
  type        = map(string)
  description = "Per-env initial website images. CI/CD updates via az CLI; TF ignores changes after first apply. Keys: staging, prod"
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
