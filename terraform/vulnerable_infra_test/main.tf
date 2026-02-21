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

resource "random_id" "stack" {
  byte_length = 4
}

resource "random_id" "bucket_suffix" {
  count       = var.vuln_bucket_count
  byte_length = 4
}

resource "random_id" "trail_bucket_suffix" {
  byte_length = 4
}

# =====================
# IAM vulnerable setup
# =====================
resource "aws_iam_account_password_policy" "weak_policy" {
  minimum_password_length        = 6
  require_lowercase_characters   = false
  require_uppercase_characters   = false
  require_numbers                = false
  require_symbols                = false
  allow_users_to_change_password = true
  max_password_age               = 0
}

resource "aws_iam_user" "vuln_user" {
  count         = var.iam_user_count
  name          = format("vuln-user-%02d-%s", count.index + 1, random_id.stack.hex)
  force_destroy = true
}

resource "aws_iam_policy" "vuln_wildcard" {
  name = "vuln-wildcard-policy-${random_id.stack.hex}"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_user_policy_attachment" "vuln_attach_custom" {
  count      = var.iam_user_count
  user       = aws_iam_user.vuln_user[count.index].name
  policy_arn = aws_iam_policy.vuln_wildcard.arn
}

resource "aws_iam_user_policy_attachment" "vuln_attach_admin" {
  count      = var.iam_user_count
  user       = aws_iam_user.vuln_user[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ====================
# S3 vulnerable setup
# ====================
resource "aws_s3_account_public_access_block" "vuln_account_pab" {
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

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

resource "aws_s3_bucket_ownership_controls" "vuln_bucket_oc" {
  count  = var.vuln_bucket_count
  bucket = aws_s3_bucket.vuln_bucket[count.index].id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_acl" "vuln_bucket_acl" {
  count = var.vuln_bucket_count
  depends_on = [
    aws_s3_bucket_ownership_controls.vuln_bucket_oc,
    aws_s3_bucket_public_access_block.vuln_bucket_pab,
    aws_s3_account_public_access_block.vuln_account_pab
  ]
  bucket = aws_s3_bucket.vuln_bucket[count.index].id
  acl    = "public-read"
}

# ============================
# CloudTrail vulnerable setup
# ============================
resource "aws_s3_bucket" "trail_bucket" {
  bucket = "vuln-cloudtrail-${var.region}-${random_id.trail_bucket_suffix.hex}"
}

resource "aws_s3_bucket_policy" "trail_bucket_policy" {
  bucket = aws_s3_bucket.trail_bucket.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.trail_bucket.arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.trail_bucket.arn}/AWSLogs/${data.aws_caller_identity.current.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "vuln_trail" {
  depends_on                    = [aws_s3_bucket_policy.trail_bucket_policy]
  name                          = "vuln-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  enable_logging                = true
  is_multi_region_trail         = var.multi_region
  include_global_service_events = true
  enable_log_file_validation    = false
}

# ============================
# CloudWatch vulnerable setup
# ============================
resource "aws_cloudwatch_log_group" "vuln_logs" {
  count             = var.cloudwatch_log_group_count
  name              = format("/vuln/log-group-%02d-%s", count.index + 1, random_id.stack.hex)
  retention_in_days = 7
}

# =========================
# Network vulnerable setup
# =========================
resource "aws_vpc" "vuln_vpc" {
  count      = var.vpc_count
  cidr_block = format("10.%d.0.0/16", 10 + count.index)
  tags = {
    Name = format("vuln-vpc-%02d-%s", count.index + 1, random_id.stack.hex)
  }
}

resource "aws_subnet" "vuln_subnet" {
  count             = var.vpc_count
  vpc_id            = aws_vpc.vuln_vpc[count.index].id
  cidr_block        = format("10.%d.1.0/24", 10 + count.index)
  availability_zone = "${var.region}a"
}

resource "aws_security_group" "vuln_sg" {
  count  = var.vpc_count
  name   = format("vuln-sg-%02d-%s", count.index + 1, random_id.stack.hex)
  vpc_id = aws_vpc.vuln_vpc[count.index].id

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
