output "grafana_endpoint" {
  description = "Grafana UI endpoint"
  value       = aws_lb.grafana.dns_name
}