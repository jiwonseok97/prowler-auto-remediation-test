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

# ==================================================
# S3 vulnerable setup
# → prowler-s3_bucket_level_public_access_block (×N)
# → prowler-s3_bucket_default_encryption       (×N)
# → prowler-s3_account_level_public_access_blocks (×1)
# ==================================================
resource "aws_s3_bucket" "vuln_bucket" {
  count         = var.vuln_bucket_count
  bucket        = format("vuln-demo-%s-%s-%02d", var.account_id, var.region, count.index + 1)
  force_destroy = true

  tags = {
    Name          = format("vuln-demo-%02d", count.index + 1)
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# PAB 전부 false → s3_bucket_level_public_access_block FAIL ×N
resource "aws_s3_bucket_public_access_block" "vuln_bucket_pab" {
  count                   = var.vuln_bucket_count
  bucket                  = aws_s3_bucket.vuln_bucket[count.index].id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

# 서버측 암호화 리소스 미생성 → s3_bucket_default_encryption FAIL ×N
# (aws_s3_bucket_server_side_encryption_configuration 의도적 미설정)

# ==================================================
# IAM 패스워드 정책 취약 설정
# → prowler-iam_password_policy_minimum_length_14
# → prowler-iam_password_policy_reuse_24
# → prowler-iam_password_policy_require_uppercase
# → prowler-iam_password_policy_require_lowercase
# → prowler-iam_password_policy_require_numbers
# → prowler-iam_password_policy_require_symbols
# ==================================================
resource "aws_iam_account_password_policy" "weak_password_policy" {
  count = var.create_weak_account_password_policy ? 1 : 0

  minimum_password_length        = 6     # 14 미달 → FAIL
  require_lowercase_characters   = false # → FAIL
  require_uppercase_characters   = false # → FAIL
  require_numbers                = false # → FAIL
  require_symbols                = false # → FAIL
  allow_users_to_change_password = true
  max_password_age               = 0
  password_reuse_prevention      = 1     # 24 미달 → FAIL
  hard_expiry                    = false
}

# ==================================================
# CloudTrail 취약 설정 (1개)
# → prowler-cloudtrail_log_file_validation_enabled
# → prowler-cloudtrail_kms_encryption_enabled
# → prowler-cloudtrail_cloudwatch_logging_enabled
# → prowler-cloudtrail_s3_dataevents_read_enabled
# → prowler-cloudtrail_s3_dataevents_write_enabled
# ==================================================
resource "aws_s3_bucket" "vuln_trail_logs" {
  count         = var.create_vuln_cloudtrail ? 1 : 0
  bucket        = format("vuln-cloudtrail-%s-%s", var.account_id, var.region)
  force_destroy = true

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_s3_bucket_policy" "vuln_trail_logs" {
  count  = var.create_vuln_cloudtrail ? 1 : 0
  bucket = aws_s3_bucket.vuln_trail_logs[0].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.vuln_trail_logs[0].arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.vuln_trail_logs[0].arn}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_cloudtrail" "vuln_trail" {
  count          = var.create_vuln_cloudtrail ? 1 : 0
  name           = "vuln-trail"
  s3_bucket_name = aws_s3_bucket.vuln_trail_logs[0].id

  # enable_log_file_validation = false → prowler-cloudtrail_log_file_validation_enabled FAIL
  enable_log_file_validation = false

  # kms_key_id 미설정 → prowler-cloudtrail_kms_encryption_enabled FAIL
  # cloud_watch_logs_group_arn 미설정 → prowler-cloudtrail_cloudwatch_logging_enabled FAIL
  # event_selector 미설정 → prowler-cloudtrail_s3_dataevents_read/write_enabled FAIL

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }

  depends_on = [aws_s3_bucket_policy.vuln_trail_logs]
}

# ==================================================
# EBS 기본 암호화 비활성화 (계정 수준)
# → prowler-ec2_ebs_default_encryption_enabled ×1 (auto-remediable)
# ==================================================
resource "aws_ebs_encryption_by_default" "vuln_ebs_enc" {
  enabled = false

  lifecycle {
    ignore_changes = []
  }
}

# ==================================================
# S3 버킷 버저닝 미설정
# → prowler-s3_bucket_versioning_enabled ×N (auto-remediable)
# ==================================================
resource "aws_s3_bucket_versioning" "vuln_bucket_versioning" {
  count  = var.vuln_bucket_count
  bucket = aws_s3_bucket.vuln_bucket[count.index].id

  versioning_configuration {
    status = "Suspended" # 버저닝 비활성 → s3_bucket_versioning_enabled FAIL
  }

  depends_on = [aws_s3_bucket.vuln_bucket]
}

# ==================================================
# KMS 키 자동 교체 비활성화
# → prowler-kms_cmk_rotation_enabled ×N (auto-remediable, IMPORT_AND_PATCH)
# ==================================================
resource "aws_kms_key" "vuln_kms" {
  count               = var.vuln_kms_key_count
  description         = format("vuln-demo-kms-%02d (rotation disabled)", count.index + 1)
  enable_key_rotation = false # → kms_cmk_rotation_enabled FAIL
  deletion_window_in_days = 7

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# ==================================================
# CloudWatch 로그 그룹 취약 설정 (KMS 없음)
# → prowler-cloudwatch_log_group_encrypted ×N
# ==================================================
resource "aws_cloudwatch_log_group" "vuln_logs" {
  count             = var.cloudwatch_log_group_count
  name              = format("/vuln/log-group-%02d", count.index + 1)
  retention_in_days = 7
  # kms_key_id 미설정 → cloudwatch_log_group_encrypted FAIL

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# ==================================================
# Default Security Group 취약 설정
# → prowler-ec2_securitygroup_default_restrict_traffic (auto-remediable)
# Default SG에 전체 인바운드/아웃바운드 허용 → FAIL
# ==================================================
resource "aws_default_security_group" "vuln_default_sg" {
  count  = var.open_default_security_group ? 1 : 0
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
    ManagedBy   = "terraform"
    ProwlerDemo = "vulnerable_infra_test"
  }
}

# ==================================================
# IAM 사용자에게 정책 직접 부여 (그룹/Role 우회)
# → prowler-iam_policy_attached_only_to_group_or_roles ×1 (review-then-apply)
# ==================================================
resource "aws_iam_user" "vuln_direct_policy" {
  count = var.create_vuln_iam_direct_policy_user ? 1 : 0
  name  = "vuln-demo-direct-policy-user"

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_policy" "vuln_readonly" {
  count       = var.create_vuln_iam_direct_policy_user ? 1 : 0
  name        = "vuln-demo-readonly-policy"
  description = "Demo: read-only policy attached directly to user (not via group/role)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:ListBucket"]
        Resource = "*"
      }
    ]
  })

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_user_policy_attachment" "vuln_direct" {
  count      = var.create_vuln_iam_direct_policy_user ? 1 : 0
  user       = aws_iam_user.vuln_direct_policy[0].name
  policy_arn = aws_iam_policy.vuln_readonly[0].arn
}

# ==================================================
# VPC (flow logs 없음 + default SG 허용)
# → prowler-vpc_flow_logs_enabled                      ×N (auto-remediable)
# → prowler-ec2_securitygroup_default_restrict_traffic ×N (auto-remediable)
# ==================================================
resource "aws_vpc" "vuln_vpc" {
  count      = var.vuln_vpc_count
  cidr_block = format("10.%d.0.0/16", 100 + count.index)

  tags = {
    Name        = format("vuln-demo-vpc-%02d", count.index + 1)
    ManagedBy   = "terraform"
    ProwlerDemo = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}
# flow logs 미설정 → vpc_flow_logs_enabled FAIL ×N
# default SG은 AWS가 자동 생성 (self-참조 ingress 규칙) → ec2_securitygroup_default_restrict_traffic FAIL ×N
