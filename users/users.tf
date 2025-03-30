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
  region = var.aws_region
}

# Define a variable for AWS region with a default
variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

# Define a variable for user permissions
variable "user_permissions" {
  description = "Map of users to their AWS permissions"
  type = map(list(string))
  default = {
    "Tejus"    = ["s3:ListBucket", "ec2:DescribeInstances"]
    "Suyash"   = ["s3:PutObject", "s3:GetObject"]
    "Soumy"    = ["ec2:StartInstances", "ec2:StopInstances"]
    "Ayush"    = ["iam:CreateUser", "iam:DeleteUser"]
    "Rohan"    = ["s3:ListAllMyBuckets"]
    "Aryan"    = ["ec2:DescribeInstances"]
    "Kriti"    = ["dynamodb:Query"]
    "Niharika" = ["lambda:InvokeFunction"]
    "Aditya"   = ["cloudwatch:PutMetricData"]
    "Meera"    = ["sqs:SendMessage", "sqs:ReceiveMessage"]
    "Tanmay"   = ["sns:Publish"]
    "Pooja"    = ["s3:DeleteObject"]
    "Karan"    = ["ec2:TerminateInstances"]
    "Sneha"    = ["rds:CreateDBInstance"]
    "Vikram"   = ["cloudtrail:StartLogging", "cloudtrail:StopLogging"]
  }
}

# Optional variable to allow completely custom input
variable "custom_user_permissions" {
  description = "Custom map of users to their AWS permissions (overrides default)"
  type = map(list(string))
  default = null
}

# Determine which user permissions to use
locals {
  final_user_permissions = var.custom_user_permissions != null ? var.custom_user_permissions : var.user_permissions
}

resource "aws_iam_policy" "user_policies" {
  for_each = local.final_user_permissions
  
  name        = "${each.key}_Policy"
  description = "Custom policy for ${each.key}"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      for action in each.value : {
        Action   = action
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_user" "users" {
  for_each = local.final_user_permissions
  name     = each.key
}

resource "aws_iam_user_policy_attachment" "attach_policy_to_user" {
  for_each = local.final_user_permissions
  
  user       = aws_iam_user.users[each.key].name
  policy_arn = aws_iam_policy.user_policies[each.key].arn
}