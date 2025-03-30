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

# Define EC2 instance configurations
variable "instance_configs" {
  default = {
    "WebServer"   = { ami = "ami-0c02fb55956c7d316", instance_type = "t2.micro", tags = { Role = "Web" } }
    "AppServer"   = { ami = "ami-0c02fb55956c7d316", instance_type = "t2.micro", tags = { Role = "App" } }
    "Database"    = { ami = "ami-0c02fb55956c7d316", instance_type = "t2.micro", tags = { Role = "DB" } }
    "CacheServer" = { ami = "ami-0c02fb55956c7d316", instance_type = "t2.micro", tags = { Role = "Cache" } }
    "Monitoring"  = { ami = "ami-0c02fb55956c7d316", instance_type = "t2.micro", tags = { Role = "Monitoring" } }
  }
}

# EC2 instances
resource "aws_instance" "secure_instances" {
  for_each = var.instance_configs

  ami           = each.value.ami
  instance_type = each.value.instance_type

  metadata_options {
    http_tokens   = "required"
    http_endpoint = "enabled"
  }

  tags = merge({ Name = each.key }, each.value.tags)
}

# Security group for instances
resource "aws_security_group" "instance_security" {
  name        = "instance-security-group"
  description = "Security group for EC2 instances"

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow HTTPS traffic from anywhere
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound traffic
  }
}

# IAM roles for instances
resource "aws_iam_role" "instance_roles" {
  for_each = var.instance_configs

  name               = "${each.key}_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Effect = "Allow",
        Principal = {
          Service = "ec2.amazonaws.com"
        },
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_instance_profile" "instance_profiles" {
  for_each = var.instance_configs

  name = "${each.key}_profile"
  role = aws_iam_role.instance_roles[each.key].name
}