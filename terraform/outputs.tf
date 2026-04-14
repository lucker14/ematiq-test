output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "loki_endpoint" {
  description = "Loki distributor endpoint"
  value       = module.loki.loki_endpoint
}

output "grafana_endpoint" {
  description = "Grafana UI endpoint"
  value       = module.grafana.grafana_endpoint
}

output "s3_bucket_name" {
  description = "S3 bucket for Loki logs"
  value       = module.storage.s3_bucket_name
}