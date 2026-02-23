terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
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

# ====================
# S3 vulnerable setup
# ====================
resource "aws_s3_bucket" "vuln_bucket" {
  count  = var.vuln_bucket_count
  bucket = format("vuln-demo-%s-%s-%02d", var.account_id, var.region, count.index + 1)
  force_destroy = true

  tags = {
    Name          = format("vuln-demo-%02d", count.index + 1)
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
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
# IAM password policy vulnerable setup
# =================================
# This intentionally weakens the account password policy to generate multiple
# auto-remediable IAM password-policy FAIL findings (minimum length, complexity,
# reuse prevention).
resource "aws_iam_account_password_policy" "weak_password_policy" {
  count = var.create_weak_account_password_policy ? 1 : 0

  minimum_password_length        = 6
  require_lowercase_characters   = false
  require_uppercase_characters   = false
  require_numbers                = false
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age               = 0
  password_reuse_prevention      = 1
  hard_expiry                    = false
}

# =================================
# CloudWatch vulnerable setup
# =================================
resource "aws_cloudwatch_log_group" "vuln_logs" {
  count             = var.cloudwatch_log_group_count
  name              = format("/vuln/log-group-%02d", count.index + 1)
  retention_in_days = 7

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# =================================
# Security Group vulnerable setup
# =================================
resource "aws_security_group" "vuln_sg" {
  count  = var.security_group_count
  name   = format("vuln-sg-%02d", count.index + 1)
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

  tags = {
    Name          = format("vuln-sg-%02d", count.index + 1)
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}
