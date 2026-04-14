variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "loki_security_group_id" {
  description = "Security group ID for Loki"
  type        = string
}

variable "loki_config" {
  description = "Loki configuration YAML"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "retention_days" {
  description = "Days to retain logs in Loki storage"
  type        = number
}

variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
}

variable "aws_account_id" {
  description = "AWS account ID for resource naming"
  type        = string
}

variable "loki_distributor_instance_type" {
  description = "Instance type for Loki distributor nodes."
  type        = string
  default     = "c5.large"
}

variable "loki_distributor_min_size" {
  description = "Minimum number of distributor instances."
  type        = number
  default     = 2
}

variable "loki_distributor_desired_capacity" {
  description = "Desired number of distributor instances."
  type        = number
  default     = 2
}

variable "loki_distributor_max_size" {
  description = "Maximum number of distributor instances."
  type        = number
  default     = 5
}

variable "loki_ingester_instance_type" {
  description = "Instance type for Loki ingester nodes."
  type        = string
  default     = "c5.xlarge"
}

variable "loki_ingester_volume_size" {
  description = "Root volume size in GB for Loki ingester WAL and chunk storage."
  type        = number
  default     = 200
}

variable "loki_ingester_min_size" {
  description = "Minimum number of ingester instances."
  type        = number
  default     = 3
}

variable "loki_ingester_desired_capacity" {
  description = "Desired number of ingester instances."
  type        = number
  default     = 3
}

variable "loki_ingester_max_size" {
  description = "Maximum number of ingester instances."
  type        = number
  default     = 10
}

variable "loki_querier_instance_type" {
  description = "Instance type for Loki querier nodes."
  type        = string
  default     = "c5.large"
}

variable "loki_querier_min_size" {
  description = "Minimum number of querier instances."
  type        = number
  default     = 2
}

variable "loki_querier_desired_capacity" {
  description = "Desired number of querier instances."
  type        = number
  default     = 2
}

variable "loki_querier_max_size" {
  description = "Maximum number of querier instances."
  type        = number
  default     = 5
}
