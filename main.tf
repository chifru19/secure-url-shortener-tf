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

# Basic policy to allow Firehose to write to S3 and CloudWatch
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