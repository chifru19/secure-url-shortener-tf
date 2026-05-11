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

  s3_configuration {
    role_arn           = aws_iam_role.firehose_role.arn
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

    cloudwatch_logging_options {
      enabled         = true
      log_group_name  = aws_cloudwatch_log_group.lambda_logs.name
      log_stream_name = "SplunkDelivery"
    }
  }
}

# --- 5. IAM ROLE FOR FIREHOSE ---
resource "aws_iam_role" "firehose_role" {
  name = "firehose_splunk_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "firehose.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_splunk_policy"
  role = aws_iam_role.firehose_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:AbortMultipartUpload",
          "s3:GetBucketLocation",
          "s3:GetObject",
          "s3:ListBucket",
          "s3:ListBucketMultipartUploads",
          "s3:PutObject"
        ]
        Effect   = "Allow"
        Resource = [
          aws_s3_bucket.app_bucket.arn,
          "${aws_s3_bucket.app_bucket.arn}/*"
        ]
      },
      {
        Action = [
          "logs:PutLogEvents"
        ]
        Effect   = "Allow"
        Resource = [
          "${aws_cloudwatch_log_group.lambda_logs.arn}:*"
        ]
      }
    ]
  })
}