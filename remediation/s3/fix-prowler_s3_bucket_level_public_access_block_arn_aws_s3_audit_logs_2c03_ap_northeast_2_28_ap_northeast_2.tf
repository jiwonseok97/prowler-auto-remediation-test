resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_2c29a4a1fa" {
  bucket                  = "audit-logs-2c03-ap-northeast-2-28"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
