resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_0980e77ddb" {
  bucket                  = "audit-logs-af73-ap-northeast-2-19"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
