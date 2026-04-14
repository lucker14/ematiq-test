output "s3_bucket_name" {
  description = "S3 bucket name for Loki logs"
  value       = aws_s3_bucket.loki_logs.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name for Loki index"
  value       = aws_dynamodb_table.loki_index.name
}