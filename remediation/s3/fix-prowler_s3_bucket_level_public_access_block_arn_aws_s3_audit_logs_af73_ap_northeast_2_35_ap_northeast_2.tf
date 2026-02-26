resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_7c24c52c9b" {
  bucket                  = "audit-logs-af73-ap-northeast-2-35"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
