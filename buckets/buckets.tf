terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  required_version = ">= 1.3.0"
}

provider "aws" {
  region = "us-east-1"
}

# --- S3 Bucket with Encryption ---
resource "aws_s3_bucket" "secure_bucket_1" {
  bucket        = "secure-bucket-1-${random_id.suffix1.hex}"
  force_destroy = true

  tags = {
    Name        = "SecureBucket1"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_1" {
  bucket = aws_s3_bucket.secure_bucket_1.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket" "secure_bucket_2" {
  bucket        = "secure-bucket-2-${random_id.suffix2.hex}"
  force_destroy = true

  tags = {
    Name        = "SecureBucket2"
    Environment = "Prod"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "encryption_2" {
  bucket = aws_s3_bucket.secure_bucket_2.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Random suffix for unique bucket names
resource "random_id" "suffix1" {
  byte_length = 4
}

resource "random_id" "suffix2" {
  byte_length = 4
}

# --- Lambda Function for Compliance Check ---
resource "aws_iam_role" "lambda_role" {
  name = "s3-lambda-enforcer-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "lambda_policy" {
  name        = "S3LambdaPolicy"
  description = "Policy to allow Lambda to manage S3 bucket encryption"
  policy      = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect   = "Allow",
        Action   = ["s3:ListAllMyBuckets", "s3:GetBucketEncryption", "s3:PutBucketEncryption"],
        Resource = "*"
      },
      {
        Effect   = "Allow",
        Action   = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"],
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "attach_policy" {
  role       = aws_iam_role.lambda_role.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

resource "aws_lambda_function" "encryption_checker" {
  function_name = "s3-encryption-checker"
  role          = aws_iam_role.lambda_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.9"

  filename         = "${path.module}/s3_encryption_checker.zip"
  source_code_hash = filebase64sha256("${path.module}/s3_encryption_checker.zip")

  environment {
    variables = {
      LOG_LEVEL = "INFO"
    }
  }
}

resource "aws_lambda_permission" "allow_s3" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.encryption_checker.function_name
  principal     = "s3.amazonaws.com"
}

# Outputs for bucket names
output "bucket_1_name" {
  value = aws_s3_bucket.secure_bucket_1.bucket
}

output "bucket_2_name" {
  value = aws_s3_bucket.secure_bucket_2.bucket
}
