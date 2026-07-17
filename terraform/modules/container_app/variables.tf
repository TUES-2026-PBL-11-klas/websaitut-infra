variable "name" {
  type = string
}

variable "resource_group_name" {
  type = string
}

variable "container_app_environment_id" {
  type = string
}

variable "identity_id" {
  type        = string
  description = "User assigned identity resource ID"
}

variable "image" {
  type = string
}

variable "port" {
  type = number
}

variable "revision_mode" {
  type    = string
  default = "Single"
}

variable "workload_profile_name" {
  type    = string
  default = "Consumption"
}

variable "min_replicas" {
  type    = number
  default = 0
}

variable "max_replicas" {
  type    = number
  default = 10
}

variable "cpu" {
  type    = number
  default = 0.5
}

variable "memory" {
  type    = string
  default = "1Gi"
}

variable "secrets" {
  type        = map(string)
  description = "Map of container secret name => KV versionless_id"
  default     = {}
}

variable "plain_env" {
  type        = map(string)
  description = "Plain-text environment variables"
  default     = {}
}

variable "secret_env" {
  type        = map(string)
  description = "Map of env var name => container secret name"
  default     = {}
}

variable "registry" {
  type = object({
    server               = string
    username             = string
    password_secret_name = string
  })
  default = null
}

variable "liveness_probe" {
  type = object({
    transport     = string
    port          = number
    initial_delay = optional(number, 0)
    timeout       = optional(number, 5)
  })
  default = null
}

variable "readiness_probe" {
  type = object({
    transport               = string
    port                    = number
    interval_seconds        = optional(number, 10)
    timeout                 = optional(number, 5)
    failure_count_threshold = optional(number, 3)
    success_count_threshold = optional(number, 1)
  })
  default = null
}

variable "startup_probe" {
  type = object({
    transport               = string
    port                    = number
    failure_count_threshold = optional(number, 3)
    interval_seconds        = optional(number, 10)
    timeout                 = optional(number, 3)
    initial_delay           = optional(number, 0)
  })
  default = null
}

variable "custom_domains" {
  type        = set(string)
  description = "Custom hostnames bound to the app. DNS (CNAME/A + asuid TXT) must exist before apply; the managed certificate is created afterwards via `az containerapp hostname bind` (see terraform/README.md)."
  default     = []
}

variable "tags" {
  type    = map(string)
  default = {}
}
