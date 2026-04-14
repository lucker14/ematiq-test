variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "grafana_security_group_id" {
  description = "Security group ID for Grafana"
  type        = string
}

variable "loki_endpoint" {
  description = "Loki endpoint"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

