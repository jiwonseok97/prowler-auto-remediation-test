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
  region = var.aws_region
}

resource "random_id" "suffix" {
  byte_length = 4
}

# IAM: over-privileged wildcard policy
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

# S3: public ACL and no encryption
resource "aws_s3_bucket" "vuln_bucket" {
  bucket = "vuln-bucket-${var.aws_region}-${random_id.suffix.hex}"
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

# CloudTrail: trail exists but logging disabled
resource "aws_s3_bucket" "trail_bucket" {
  bucket = "vuln-cloudtrail-${var.aws_region}-${random_id.suffix.hex}"
}

resource "aws_cloudtrail" "vuln_trail" {
  name                          = "vuln-trail"
  s3_bucket_name                = aws_s3_bucket.trail_bucket.id
  enable_logging                = false
  is_multi_region_trail         = var.multi_region
  include_global_service_events = false
  enable_log_file_validation    = false
}

# CloudWatch: log group without kms encryption
resource "aws_cloudwatch_log_group" "vuln_logs" {
  name              = "/vuln/log-group"
  retention_in_days = 7
}

# VPC/EC2: security group open to all ports/protocols
resource "aws_vpc" "vuln_vpc" {
  cidr_block = "10.10.0.0/16"
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
