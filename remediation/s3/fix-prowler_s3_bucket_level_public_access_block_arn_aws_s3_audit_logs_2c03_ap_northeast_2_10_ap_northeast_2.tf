resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_fc15ab42d8" {
  bucket                  = "audit-logs-2c03-ap-northeast-2-10"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
