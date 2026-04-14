output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.main.id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = aws_subnet.private[*].id
}

output "public_subnet_ids" {
  description = "Public subnet IDs"
  value       = aws_subnet.public[*].id
}

output "loki_security_group_id" {
  description = "Security group for Loki"
  value       = aws_security_group.loki.id
}

output "grafana_security_group_id" {
  description = "Security group for Grafana"
  value       = aws_security_group.grafana.id
}