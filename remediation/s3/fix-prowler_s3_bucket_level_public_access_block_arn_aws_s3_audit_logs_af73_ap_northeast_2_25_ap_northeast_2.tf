resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_bf0f1ea752" {
  bucket                  = "audit-logs-af73-ap-northeast-2-25"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
