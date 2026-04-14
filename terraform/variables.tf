# TODO: adjust these root defaults for your account, region, and environment before applying.
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Public subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "private_subnets" {
  description = "Private subnet CIDR blocks"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24", "10.0.12.0/24"]
}

variable "availability_zones" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "loki_config" {
  description = "Loki configuration as YAML string"
  type        = string
  default     = "" # TODO: provide your Loki configuration YAML here
}

variable "retention_days" {
  description = "Days to retain logs"
  type        = number
  default     = 30
}

variable "enable_ecs" {
  description = "Enable ECS FireLens sample resources."
  type        = bool
  default     = false
}

variable "enable_ec2_agent" {
  description = "Enable EC2 Fluent Bit agent deployment."
  type        = bool
  default     = false
}

variable "enable_example_ecs_task" {
  description = "Deploy a sample ECS task definition demonstrating FireLens sidecar integration."
  type        = bool
  default     = false
}

variable "ecs_firelens_log_group_retention" {
  description = "CloudWatch log retention for the ECS FireLens router log group."
  type        = number
  default     = 1
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
