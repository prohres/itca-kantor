variable "desired_count" {
  description = "Running tasks; 0 stops the app between sessions (the ALB keeps running and billing)"
  type        = number
  default     = 1
  validation {
    condition     = contains([0, 1], var.desired_count)
    error_message = "Use 1 (on) or 0 (off)."
  }
}
