# Storage module - S3 bucket and DynamoDB table for Loki

resource "aws_s3_bucket" "loki_logs" {
  bucket = "loki-logs-${data.aws_caller_identity.current.account_id}-${var.environment}"

  tags = {
    Name        = "loki-logs-${var.environment}"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "loki_logs" {
  bucket = aws_s3_bucket.loki_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "loki_logs" {
  bucket = aws_s3_bucket.loki_logs.id

  rule {
    id     = "archive_and_expire"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = var.transition_to_ia_days
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = var.transition_to_glacier_days
      storage_class = "GLACIER"
    }

    expiration {
      days = var.expiration_days
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "loki_logs" {
  bucket = aws_s3_bucket.loki_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_dynamodb_table" "loki_index" {
  name         = "loki-index-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "hash_key"
  range_key    = "range_key"

  attribute {
    name = "hash_key"
    type = "S"
  }

  attribute {
    name = "range_key"
    type = "S"
  }

  global_secondary_index {
    name            = "loki-gsi"
    hash_key        = "range_key"
    range_key       = "hash_key"
    projection_type = "ALL"
  }

  ttl {
    attribute_name = "ttl"
    enabled        = true
  }

  tags = {
    Name        = "loki-index-${var.environment}"
    Environment = var.environment
  }
}

data "aws_caller_identity" "current" {}