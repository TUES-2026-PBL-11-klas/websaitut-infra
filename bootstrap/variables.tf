variable "subscription_id" {
  type        = string
  description = "Azure subscription ID"
}

variable "location" {
  type        = string
  default     = "polandcentral"
  description = "Azure region — must match live/'s location"
}
