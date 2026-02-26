resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_6c6752916b" {
  bucket                  = "audit-logs-af73-ap-northeast-2-30"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
