output "loki_endpoint" {
  description = "Loki distributor endpoint"
  value       = aws_lb.loki.dns_name
}

output "loki_querier_endpoint" {
  description = "Loki querier endpoint"
  value       = "${aws_lb.loki.dns_name}:3101"
}