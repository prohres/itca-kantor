variable "admin_account_id" {
  description = "CI hub account: OIDC roles and the shared registry"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.admin_account_id))
    error_message = "A 12-digit AWS account id."
  }
}

variable "dev_account_id" {
  description = "Workload account: the app runtime"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.dev_account_id))
    error_message = "A 12-digit AWS account id."
  }
}

variable "desired_count" {
  description = "Running tasks; 0 stops the app between sessions (the ALB keeps running and billing)"
  type        = number
  default     = 1
  validation {
    condition     = contains([0, 1], var.desired_count)
    error_message = "Use 1 (on) or 0 (off)."
  }
}
