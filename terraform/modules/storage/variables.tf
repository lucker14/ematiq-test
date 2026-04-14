variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_days" {
  description = "Days to retain logs in S3"
  type        = number
}

variable "transition_to_ia_days" {
  description = "Days before S3 objects move to STANDARD_IA."
  type        = number
  default     = 30
}

variable "transition_to_glacier_days" {
  description = "Days before S3 objects move to GLACIER."
  type        = number
  default     = 90
}

variable "expiration_days" {
  description = "Days before S3 objects are deleted."
  type        = number
  default     = 365
}
