variable "account_id" {
  description = "sketch-dev: the whole stack (accounts.auto.tfvars locally, TF_VAR_account_id from ci-templates tf-setup in CI)"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.account_id))
    error_message = "A 12-digit AWS account id."
  }
}

variable "admin_account_id" {
  description = "CI hub account: the gha roles that push images and deploy (tf-vars in CI)"
  type        = string
  validation {
    condition     = can(regex("^[0-9]{12}$", var.admin_account_id))
    error_message = "A 12-digit AWS account id."
  }
}

variable "assume_role_name" {
  description = "Local runs only: role to assume in sketch-dev (OrganizationAccountAccessRole); CI already runs as its role there"
  type        = string
  default     = null
  validation {
    condition     = var.assume_role_name == null || can(regex("^[A-Za-z0-9+=,.@_-]{1,64}$", var.assume_role_name))
    error_message = "An IAM role name (not an ARN), or null."
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
