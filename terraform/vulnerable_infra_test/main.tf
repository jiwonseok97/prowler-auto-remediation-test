terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.5"
    }
  }
}

provider "aws" {
  region = var.region
}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

resource "random_id" "stack" {
  byte_length = 4
}

resource "random_id" "bucket_suffix" {
  count       = var.vuln_bucket_count
  byte_length = 4
}

# ====================
# S3 vulnerable setup
# ====================
resource "aws_s3_bucket" "vuln_bucket" {
  count  = var.vuln_bucket_count
  bucket = format("vuln-demo-%s-%02d-%s", var.region, count.index + 1, random_id.bucket_suffix[count.index].hex)
}

resource "aws_s3_bucket_public_access_block" "vuln_bucket_pab" {
  count                   = var.vuln_bucket_count
  bucket                  = aws_s3_bucket.vuln_bucket[count.index].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# =================================
# CloudWatch vulnerable setup
# =================================
resource "aws_cloudwatch_log_group" "vuln_logs" {
  count             = var.cloudwatch_log_group_count
  name              = format("/vuln/log-group-%02d-%s", count.index + 1, random_id.stack.hex)
  retention_in_days = 7
}

# =================================
# Security Group vulnerable setup
# =================================
resource "aws_security_group" "vuln_sg" {
  count  = var.security_group_count
  name   = format("vuln-sg-%02d-%s", count.index + 1, random_id.stack.hex)
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
