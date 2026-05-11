# --- 1. SECURE DATABASE (DYNAMODB) ---
resource "aws_dynamodb_table" "url_db" {
  name         = "urls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }
}

# --- 2. SECURE STORAGE (S3) ---
resource "aws_s3_bucket" "app_bucket" {
  bucket = "frank-shortener-secure-storage"
}

resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "privacy" {
  bucket = aws_s3_bucket.app_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# --- 3. OBSERVABILITY (CLOUDWATCH) ---
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/url_shortener"
  retention_in_days = 14
}

# --- 4. TELEMETRY PIPELINE (SPLUNK) ---
resource "aws_kinesis_firehose_delivery_stream" "splunk_stream" {
  name        = "shortener-to-splunk"
  destination = "splunk"

  # S3 Configuration is REQUIRED for Splunk destinations as a backup for failed events
  s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn # Ensure you have this IAM role defined
    bucket_arn         = aws_s3_bucket.app_bucket.arn
    buffer_size        = 5
    buffer_interval    = 300
    compression_format = "GZIP"
  }

  splunk_configuration {
    hec_endpoint               = "https://your-splunk-instance:8088"
    hec_token                  = "YOUR-HEC-TOKEN"
    hec_acknowledgment_timeout = 300
    hec_endpoint_type          = "Raw"
    s3_backup_mode             = "FailedEventsOnly"

    # CloudWatch logging is required for observability within the Splunk block
    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.lambda_logs.name
      log_stream_name = "SplunkDelivery"
    }
  }
}