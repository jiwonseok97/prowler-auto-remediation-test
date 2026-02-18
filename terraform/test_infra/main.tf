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

resource "random_id" "suffix" {
  byte_length = 4
}

# IAM 취약 예시: 약한 패스워드 정책 + wildcard 권한
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
  name          = "vuln-user"
  force_destroy = true
}

resource "aws_iam_policy" "vuln_wildcard" {
  name = "vuln-wildcard-policy"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = "*"
      Resource = "*"
    }]
  })
}

resource "aws_iam_user_policy_attachment" "vuln_attach" {
  user       = aws_iam_user.vuln_user.name
  policy_arn = aws_iam_policy.vuln_wildcard.arn
}

# S3 취약 예시: public-read, encryption/로깅 미설정
resource "aws_s3_bucket" "vuln_bucket" {
  bucket = "vuln-bucket-${var.region}-${random_id.suffix.hex}"
}

resource "aws_s3_bucket_ownership_controls" "vuln_bucket_oc" {
  bucket = aws_s3_bucket.vuln_bucket.id
  rule {
    object_ownership = "BucketOwnerPreferred"
  }
}

resource "aws_s3_bucket_public_access_block" "vuln_pab" {
  bucket                  = aws_s3_bucket.vuln_bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_acl" "vuln_bucket_acl" {
  depends_on = [
    aws_s3_bucket_ownership_controls.vuln_bucket_oc,
    aws_s3_bucket_public_access_block.vuln_pab
  ]
  bucket = aws_s3_bucket.vuln_bucket.id
  acl    = "public-read"
}

# CloudTrail 취약 예시: 파일 검증/KMS 암호화 없음
resource "aws_s3_bucket" "trail_bucket" {
  bucket = "vuln-cloudtrail-${var.region}-${random_id.suffix.hex}"
}

resource "aws_cloudtrail" "vuln_trail" {
  name                          = "vuln-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  enable_logging                = true
  is_multi_region_trail         = var.multi_region
  include_global_service_events = true
  enable_log_file_validation    = false
}

# CloudWatch 취약 예시: 암호화 없는 로그 그룹
resource "aws_cloudwatch_log_group" "vuln_logs" {
  name              = "/vuln/log-group"
  retention_in_days = 7
}

# Network/VPC 취약 예시: 전체 오픈 SG, Flow logs 미설정
resource "aws_vpc" "vuln_vpc" {
  cidr_block = "10.10.0.0/16"
}

resource "aws_subnet" "vuln_subnet" {
  vpc_id            = aws_vpc.vuln_vpc.id
  cidr_block        = "10.10.1.0/24"
  availability_zone = "${var.region}a"
}

resource "aws_security_group" "vuln_sg" {
  name   = "vuln-sg"
  vpc_id = aws_vpc.vuln_vpc.id

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
