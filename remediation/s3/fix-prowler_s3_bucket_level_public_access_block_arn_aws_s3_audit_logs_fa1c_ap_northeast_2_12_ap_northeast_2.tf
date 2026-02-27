resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_5b5f9b5b8f" {
  bucket                  = "audit-logs-fa1c-ap-northeast-2-12"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
