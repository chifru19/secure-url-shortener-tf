# --- 0. LOCALSTACK PROVIDER ---
provider "aws" {
  region                      = "us-east-1"
  access_key                  = "test"
  secret_key                  = "test"
  
  # These 4 lines are CRITICAL for LocalStack success
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  s3_use_path_style           = true

  endpoints {
    dynamodb = "http://localhost:4566"
    s3       = "http://localhost:4566"
    lambda   = "http://localhost:4566"
    iam      = "http://localhost:4566"
    firehose = "http://localhost:4566"
    logs     = "http://localhost:4566"
  }
}

# --- 1. SECURE DATABASE ---
resource "aws_dynamodb_table" "url_db" {
  name         = "urls"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  server_side_encryption { enabled = true }
  point_in_time_recovery { enabled = true }
}

# --- 2. SECURE STORAGE ---
resource "aws_s3_bucket" "app_bucket" {
  bucket = "frank-shortener-secure-storage"
}

resource "aws_s3_bucket_versioning" "v" {
  bucket = aws_s3_bucket.app_bucket.id
  versioning_configuration { status = "Enabled" }
}

resource "aws_s3_bucket_public_access_block" "p" {
  bucket = aws_s3_bucket.app_bucket.id
  block_public_acls, block_public_policy, ignore_public_acls, restrict_public_buckets = true, true, true, true
}

# --- 3. THE LAMBDA FUNCTION ---
resource "aws_iam_role" "lambda_role" {
  name = "url_shortener_lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

resource "aws_lambda_function" "url_shortener" {
  filename      = "lambda.zip"
  function_name = "url_shortener_func"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "python3.9"

  environment {
    variables = {
      DYNAMODB_TABLE = aws_dynamodb_table.url_db.name
    }
  }
}

# --- 4. OBSERVABILITY ---
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/url_shortener"
  retention_in_days = 14
}

resource "aws_kinesis_firehose_delivery_stream" "splunk_stream" {
  name        = "shortener-to-splunk"
  destination = "splunk"

  s3_configuration {
    role_arn        = aws_iam_role.firehose_role.arn
    bucket_arn      = aws_s3_bucket.app_bucket.arn
    buffer_size     = 5
    buffer_interval = 300
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

# --- 5. FIREHOSE IAM ---
resource "aws_iam_role" "firehose_role" {
  name = "firehose_splunk_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{ Action = "sts:AssumeRole", Effect = "Allow", Principal = { Service = "firehose.amazonaws.com" } }]
  })
}

resource "aws_iam_role_policy" "firehose_policy" {
  name = "firehose_splunk_policy"
  role = aws_iam_role.firehose_role.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Action = ["s3:*"], Effect = "Allow", Resource = [aws_s3_bucket.app_bucket.arn, "${aws_s3_bucket.app_bucket.arn}/*"] },
      { Action = ["logs:PutLogEvents"], Effect = "Allow", Resource = ["*"] }
    ]
  })
}