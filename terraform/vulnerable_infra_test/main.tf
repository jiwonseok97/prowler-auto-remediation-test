terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "random" {}

data "aws_caller_identity" "current" {}

data "aws_vpc" "default" {
  default = true
}

data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

resource "random_id" "name_seed" {
  byte_length = 2
  keepers = {
    account_id = var.account_id
    region     = var.region
  }
}

resource "random_password" "rds_master" {
  length  = 16
  special = true
  override_special = "!#$%&*()-_=+[]{}:;,.?"
}

locals {
  is_remediate          = var.mode == "remediate"
  name_seed             = random_id.name_seed.hex
  s3_name_prefix        = "audit-logs-${local.name_seed}-${var.region}"
  trail_name            = "orgtrail-${local.name_seed}"
  log_group_prefix      = "/ops/audit-${local.name_seed}"
  iam_user_name         = "svc-audit-${local.name_seed}"
  iam_group_name        = "grp-audit-${local.name_seed}"
  iam_policy_name       = "pol-audit-${local.name_seed}"
  s3_data_event_arns    = [for b in aws_s3_bucket.vuln_bucket : "${b.arn}/"]
  s3_bucket_arns        = [for b in aws_s3_bucket.vuln_bucket : b.arn]
  s3_bucket_object_arns = [for b in aws_s3_bucket.vuln_bucket : "${b.arn}/*"]
  open_sg_ports         = [22, 3389, 80, 443, 3306, 5432]

  sg_ingress_rules = local.is_remediate ? [] : [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]

  sg_egress_rules = local.is_remediate ? [] : [
    {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["10.0.0.0/8"]
    }
  ]
}

# ==================================================
# S3 vulnerable setup
# → prowler-s3_bucket_level_public_access_block (×N)
# → prowler-s3_bucket_default_encryption       (×N)
# → prowler-s3_account_level_public_access_blocks (×1)
# ==================================================
resource "aws_s3_bucket" "vuln_bucket" {
  count         = var.vuln_bucket_count
  bucket        = format("%s-%02d", local.s3_name_prefix, count.index + 1)
  force_destroy = true


  tags = {
    Name          = format("audit-logs-%02d", count.index + 1)
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# PAB 전부 false → s3_bucket_level_public_access_block FAIL ×N
resource "aws_s3_bucket_public_access_block" "vuln_bucket_pab" {
  count                   = var.vuln_bucket_count
  bucket                  = aws_s3_bucket.vuln_bucket[count.index].id
  block_public_acls       = local.is_remediate
  block_public_policy     = local.is_remediate
  ignore_public_acls      = local.is_remediate
  restrict_public_buckets = local.is_remediate
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vuln_bucket_sse" {
  count  = local.is_remediate ? var.vuln_bucket_count : 0
  bucket = aws_s3_bucket.vuln_bucket[count.index].id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_policy" "vuln_bucket_secure_transport" {
  count  = local.is_remediate ? var.vuln_bucket_count : 0
  bucket = aws_s3_bucket.vuln_bucket[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "DenyInsecureTransport"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.vuln_bucket[count.index].arn,
          "${aws_s3_bucket.vuln_bucket[count.index].arn}/*"
        ]
        Condition = {
          Bool = { "aws:SecureTransport" = "false" }
        }
      }
    ]
  })
}

resource "aws_s3_account_public_access_block" "account_pab" {
  block_public_acls       = local.is_remediate
  block_public_policy     = local.is_remediate
  ignore_public_acls      = local.is_remediate
  restrict_public_buckets = local.is_remediate
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

  minimum_password_length        = local.is_remediate ? 14 : 6
  require_lowercase_characters   = local.is_remediate
  require_uppercase_characters   = local.is_remediate
  require_numbers                = local.is_remediate
  require_symbols                = local.is_remediate
  allow_users_to_change_password = true
  max_password_age               = 0
  password_reuse_prevention      = local.is_remediate ? 24 : 1
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
  count         = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  bucket        = format("trail-logs-%s-%s-%02d", local.name_seed, var.region, count.index + 1)
  force_destroy = true

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_s3_bucket_policy" "vuln_trail_logs" {
  count  = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  bucket = aws_s3_bucket.vuln_trail_logs[count.index].id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "AWSCloudTrailAclCheck"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:GetBucketAcl"
        Resource  = aws_s3_bucket.vuln_trail_logs[count.index].arn
      },
      {
        Sid       = "AWSCloudTrailWrite"
        Effect    = "Allow"
        Principal = { Service = "cloudtrail.amazonaws.com" }
        Action    = "s3:PutObject"
        Resource  = "${aws_s3_bucket.vuln_trail_logs[count.index].arn}/AWSLogs/${var.account_id}/*"
        Condition = {
          StringEquals = { "s3:x-amz-acl" = "bucket-owner-full-control" }
        }
      }
    ]
  })
}

resource "aws_kms_key" "trail_kms" {
  count                   = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  description             = "cloudtrail-kms-${local.name_seed}-${count.index + 1}"
  enable_key_rotation     = true
  deletion_window_in_days = 7

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_cloudwatch_log_group" "trail_logs" {
  count             = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  name              = format("%s/cloudtrail-%02d", local.log_group_prefix, count.index + 1)
  retention_in_days = 30
  kms_key_id        = local.is_remediate ? aws_kms_key.trail_kms[count.index].arn : null

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_role" "trail_cloudwatch_role" {
  count = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  name  = "role-cloudtrail-${local.name_seed}-${count.index + 1}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "cloudtrail.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_policy" "trail_cloudwatch_policy" {
  count       = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  name        = "pol-cloudtrail-${local.name_seed}-${count.index + 1}"
  description = "Allow CloudTrail to write to CloudWatch Logs"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "${aws_cloudwatch_log_group.trail_logs[count.index].arn}:*"
      }
    ]
  })

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_role_policy_attachment" "trail_cloudwatch_attach" {
  count      = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  role       = aws_iam_role.trail_cloudwatch_role[count.index].name
  policy_arn = aws_iam_policy.trail_cloudwatch_policy[count.index].arn
}

resource "aws_cloudtrail" "vuln_trail" {
  count          = var.create_vuln_cloudtrail ? var.cloudtrail_trail_count : 0
  name           = format("%s-%02d", local.trail_name, count.index + 1)
  s3_bucket_name = aws_s3_bucket.vuln_trail_logs[count.index].id

  # enable_log_file_validation = local.is_remediate → prowler-cloudtrail_log_file_validation_enabled FAIL
  enable_log_file_validation = local.is_remediate

  # kms_key_id 미설정 → prowler-cloudtrail_kms_encryption_enabled FAIL
  # cloud_watch_logs_group_arn 미설정 → prowler-cloudtrail_cloudwatch_logging_enabled FAIL
  # event_selector 미설정 → prowler-cloudtrail_s3_dataevents_read/write_enabled FAIL

  kms_key_id                 = local.is_remediate ? aws_kms_key.trail_kms[count.index].arn : null
  cloud_watch_logs_group_arn = local.is_remediate ? "${aws_cloudwatch_log_group.trail_logs[count.index].arn}:*" : null
  cloud_watch_logs_role_arn  = local.is_remediate ? aws_iam_role.trail_cloudwatch_role[count.index].arn : null

  dynamic "event_selector" {
    for_each = local.is_remediate ? [1] : []
    content {
      read_write_type           = "All"
      include_management_events = true
      data_resource {
        type   = "AWS::S3::Object"
        values = local.s3_data_event_arns
      }
    }
  }

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
# 주의: ec2:DisableEbsEncryptionByDefault 권한 필요
#       GitHubActionsProwlerRole에 권한이 없으면 create_vuln_ebs_disabled=false
# ==================================================
resource "aws_ebs_encryption_by_default" "vuln_ebs_enc" {
  count   = var.create_vuln_ebs_disabled ? 1 : 0
  enabled = local.is_remediate ? true : false
}

# ==================================================
# S3 버킷 버저닝 미설정
# → prowler-s3_bucket_versioning_enabled ×N (auto-remediable)
# ==================================================
resource "aws_s3_bucket_versioning" "vuln_bucket_versioning" {
  count  = var.vuln_bucket_count
  bucket = aws_s3_bucket.vuln_bucket[count.index].id

  versioning_configuration {
    status = local.is_remediate ? "Enabled" : "Suspended"
  }

  depends_on = [aws_s3_bucket.vuln_bucket]
}

# ==================================================
# KMS 키 자동 교체 비활성화
# → prowler-kms_cmk_rotation_enabled ×N (auto-remediable, IMPORT_AND_PATCH)
# ==================================================
resource "aws_kms_key" "vuln_kms" {
  count                   = var.vuln_kms_key_count
  description             = format("ops-kms-%s-%02d", local.name_seed, count.index + 1)
  enable_key_rotation     = local.is_remediate ? true : false # → kms_cmk_rotation_enabled FAIL
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
  name              = format("%s/app-%02d", local.log_group_prefix, count.index + 1)
  retention_in_days = 7
  kms_key_id        = local.is_remediate ? aws_kms_key.vuln_kms[0].arn : null

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

  dynamic "ingress" {
    for_each = local.sg_ingress_rules
    content {
      from_port   = ingress.value.from_port
      to_port     = ingress.value.to_port
      protocol    = ingress.value.protocol
      cidr_blocks = ingress.value.cidr_blocks
    }
  }

  dynamic "egress" {
    for_each = local.sg_egress_rules
    content {
      from_port   = egress.value.from_port
      to_port     = egress.value.to_port
      protocol    = egress.value.protocol
      cidr_blocks = egress.value.cidr_blocks
    }
  }

  tags = {
    ManagedBy   = "terraform"
    ProwlerDemo = "vulnerable_infra_test"
  }
}

# ==================================================
# Open Security Groups (0.0.0.0/0)
# → EC2/Network ingress exposure checks 증가
# ==================================================
resource "aws_security_group" "vuln_open_sg" {
  count  = local.is_remediate ? 0 : var.vuln_open_sg_count
  name   = format("sec-open-%s-%02d", local.name_seed, count.index + 1)
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = local.open_sg_ports[count.index % length(local.open_sg_ports)]
    to_port     = local.open_sg_ports[count.index % length(local.open_sg_ports)]
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# ==================================================
# IAM 사용자에게 정책 직접 부여 (그룹/Role 우회)
# → prowler-iam_policy_attached_only_to_group_or_roles ×1 (review-then-apply)
# ==================================================
resource "aws_iam_user" "vuln_direct_policy" {
  count = var.create_vuln_iam_direct_policy_user ? 1 : 0
  name  = local.iam_user_name

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_group" "vuln_direct_group" {
  count = var.create_vuln_iam_direct_policy_user ? 1 : 0
  name  = local.iam_group_name
}

resource "aws_iam_user_group_membership" "vuln_user_group" {
  count = var.create_vuln_iam_direct_policy_user ? 1 : 0
  user  = aws_iam_user.vuln_direct_policy[0].name
  groups = [
    aws_iam_group.vuln_direct_group[0].name,
  ]
}

resource "aws_iam_policy" "vuln_readonly" {
  count       = var.create_vuln_iam_direct_policy_user ? 1 : 0
  name        = local.iam_policy_name
  description = "Demo: read-only policy attached directly to user (not via group/role)"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = local.is_remediate ? [
      {
        Effect   = "Allow"
        Action   = ["s3:ListBucket", "s3:GetObject"]
        Resource = concat(local.s3_bucket_arns, local.s3_bucket_object_arns)
      }
      ] : [
      {
        Effect   = "Allow"
        Action   = ["*"]
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
  count      = var.create_vuln_iam_direct_policy_user && !local.is_remediate ? 1 : 0
  user       = aws_iam_user.vuln_direct_policy[0].name
  policy_arn = aws_iam_policy.vuln_readonly[0].arn
}

resource "aws_iam_group_policy_attachment" "vuln_group_attach" {
  count      = var.create_vuln_iam_direct_policy_user && local.is_remediate ? 1 : 0
  group      = aws_iam_group.vuln_direct_group[0].name
  policy_arn = aws_iam_policy.vuln_readonly[0].arn
}

# ==================================================
# Multiple admin IAM users (direct policy attach)
# ==================================================
resource "aws_iam_user" "vuln_admin_users" {
  count = var.create_vuln_admin_iam_users && !local.is_remediate ? var.vuln_admin_iam_user_count : 0
  name  = format("svc-admin-%s-%02d", local.name_seed, count.index + 1)

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_iam_user_policy_attachment" "vuln_admin_attach" {
  count      = var.create_vuln_admin_iam_users && !local.is_remediate ? var.vuln_admin_iam_user_count : 0
  user       = aws_iam_user.vuln_admin_users[count.index].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# ==================================================
# RDS (storage encryption, backups, multi-az)
# ==================================================
resource "aws_db_subnet_group" "rds_subnets" {
  count      = var.rds_instance_count > 0 ? 1 : 0
  name       = "db-subnet-${local.name_seed}"
  subnet_ids = data.aws_subnets.default.ids

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_security_group" "rds_sg" {
  count  = var.rds_instance_count > 0 ? 1 : 0
  name   = "sec-db-${local.name_seed}"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = local.is_remediate ? ["10.0.0.0/8"] : ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_db_instance" "vuln_rds" {
  count                               = var.rds_instance_count
  identifier                          = format("app-db-%s-%02d", local.name_seed, count.index + 1)
  engine                              = "postgres"
  instance_class                      = "db.t3.micro"
  allocated_storage                   = 20
  storage_type                        = "gp3"
  db_name                             = "appdb"
  username                            = "appadmin"
  password                            = random_password.rds_master.result
  db_subnet_group_name                = aws_db_subnet_group.rds_subnets[0].name
  vpc_security_group_ids              = [aws_security_group.rds_sg[0].id]
  publicly_accessible                 = local.is_remediate ? false : true
  storage_encrypted                   = local.is_remediate
  backup_retention_period             = local.is_remediate ? 7 : 0
  deletion_protection                 = local.is_remediate
  auto_minor_version_upgrade          = local.is_remediate
  multi_az                            = local.is_remediate
  iam_database_authentication_enabled = local.is_remediate
  enabled_cloudwatch_logs_exports     = local.is_remediate ? ["postgresql", "upgrade"] : []
  copy_tags_to_snapshot               = local.is_remediate
  skip_final_snapshot                 = true
  apply_immediately                   = true

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

# ==================================================
# EFS (encryption + backups)
# ==================================================
resource "aws_security_group" "efs_sg" {
  count  = var.enable_extended_services && var.efs_count > 0 ? 1 : 0
  name   = "sec-efs-${local.name_seed}"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 2049
    to_port     = 2049
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_efs_file_system" "vuln_efs" {
  count           = var.enable_extended_services ? var.efs_count : 0
  encrypted       = local.is_remediate
  throughput_mode = "bursting"
}

resource "aws_efs_mount_target" "vuln_efs_mt" {
  count           = var.enable_extended_services ? var.efs_count : 0
  file_system_id  = aws_efs_file_system.vuln_efs[count.index].id
  subnet_id       = data.aws_subnets.default.ids[0]
  security_groups = [aws_security_group.efs_sg[0].id]
}

resource "aws_efs_backup_policy" "vuln_efs_backup" {
  count          = var.enable_extended_services ? var.efs_count : 0
  file_system_id = aws_efs_file_system.vuln_efs[count.index].id

  backup_policy {
    status = local.is_remediate ? "ENABLED" : "DISABLED"
  }
}

# ==================================================
# ALB (access logs, deletion protection)
# ==================================================
resource "aws_s3_bucket" "alb_logs" {
  count         = var.enable_extended_services && var.alb_count > 0 ? 1 : 0
  bucket        = format("alb-logs-%s-%s", local.name_seed, var.region)
  force_destroy = true

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_s3_bucket_public_access_block" "alb_logs_pab" {
  count                   = var.enable_extended_services && var.alb_count > 0 ? 1 : 0
  bucket                  = aws_s3_bucket.alb_logs[0].id
  block_public_acls       = local.is_remediate
  block_public_policy     = local.is_remediate
  ignore_public_acls      = local.is_remediate
  restrict_public_buckets = local.is_remediate
}

resource "aws_security_group" "alb_sg" {
  count  = var.enable_extended_services && var.alb_count > 0 ? 1 : 0
  name   = "sec-alb-${local.name_seed}"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/8"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_lb" "vuln_alb" {
  count                      = var.enable_extended_services ? var.alb_count : 0
  name                       = format("alb-core-%s-%02d", local.name_seed, count.index + 1)
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb_sg[0].id]
  subnets                    = data.aws_subnets.default.ids
  enable_deletion_protection = local.is_remediate

  access_logs {
    bucket  = aws_s3_bucket.alb_logs[0].id
    enabled = local.is_remediate
  }

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_lb_target_group" "vuln_alb_tg" {
  count    = var.enable_extended_services ? var.alb_count : 0
  name     = format("tg-core-%s-%02d", local.name_seed, count.index + 1)
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.aws_vpc.default.id

  health_check {
    path = "/"
  }
}

resource "aws_lb_listener" "vuln_alb_listener" {
  count             = var.enable_extended_services ? var.alb_count : 0
  load_balancer_arn = aws_lb.vuln_alb[count.index].arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"
    fixed_response {
      content_type = "text/plain"
      message_body = "ok"
      status_code  = "200"
    }
  }
}

# ==================================================
# SNS / SQS (encryption at rest)
# ==================================================
resource "aws_sns_topic" "vuln_sns" {
  count             = var.enable_extended_services ? var.sns_topic_count : 0
  name              = format("topic-audit-%s-%02d", local.name_seed, count.index + 1)
  kms_master_key_id = local.is_remediate ? aws_kms_key.vuln_kms[0].arn : null

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}

resource "aws_sqs_queue" "vuln_sqs" {
  count                   = var.enable_extended_services ? var.sqs_queue_count : 0
  name                    = format("queue-audit-%s-%02d", local.name_seed, count.index + 1)
  sqs_managed_sse_enabled = local.is_remediate
  kms_master_key_id       = local.is_remediate ? aws_kms_key.vuln_kms[0].arn : null

  tags = {
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
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
    Name          = format("core-net-%s-%02d", local.name_seed, count.index + 1)
    ManagedBy     = "terraform"
    ProwlerDemo   = "vulnerable_infra_test"
    CleanupTarget = "true"
  }
}
# flow logs 미설정 → vpc_flow_logs_enabled FAIL ×N
# default SG은 AWS가 자동 생성 (self-참조 ingress 규칙) → ec2_securitygroup_default_restrict_traffic FAIL ×N
