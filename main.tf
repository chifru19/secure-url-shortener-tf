# --- 1. SECURE DATABASE (DYNAMODB) ---
resource "aws_dynamodb_table" "url_db" {
  name         = "urls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  # FIX for AWS018: Explicit Encryption at rest
  server_side_encryption {
    enabled = true
  }

  # FIX for AWS086: Enable Point-in-time recovery for IR
  point_in_time_recovery {
    enabled = true
  }
}

# --- 2. SECURE STORAGE (S3) ---
resource "aws_s3_bucket" "app_bucket" {
  bucket = "frank-shortener-secure-storage"
}

# FIX: Add Versioning (Required by most security audits)
resource "aws_s3_bucket_versioning" "app_bucket_versioning" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

# FIX for AWS002: Block all public access
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
  retention_in_days = 14 # FIX: Compliance requires a specific retention period
  # FIX: kms_key_id would go here for enterprise, but retention helps for now
}

# --- 4. TELEMETRY PIPELINE (SPLUNK) ---
resource "aws_kinesis_firehose_delivery_stream" "splunk_stream" {
  name        = "shortener-to-splunk"
  destination = "splunk"

  splunk_configuration {
    hec_endpoint               = "https://your-splunk-instance:8088"
    hec_token                  = "YOUR-HEC-TOKEN"
    hec_acknowledgment_timeout = 300
  }
}