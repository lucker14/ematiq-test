variable "loki_endpoint" {
  description = "Loki endpoint. This is used by the Fluent Bit/FireLens output plugin."
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "enable_ecs" {
  description = "Enable ECS FireLens sample resources."
  type        = bool
  default     = false
}

variable "enable_ec2_agent" {
  description = "Enable standalone EC2 Fluent Bit agent deployment."
  type        = bool
  default     = false
}

variable "enable_example_ecs_task" {
  description = "Deploy a sample ECS task definition demonstrating FireLens."
  type        = bool
  default     = false
}

variable "ecs_firelens_log_group_retention" {
  description = "Retention days for the ECS FireLens router CloudWatch log group."
  type        = number
  default     = 1
}
