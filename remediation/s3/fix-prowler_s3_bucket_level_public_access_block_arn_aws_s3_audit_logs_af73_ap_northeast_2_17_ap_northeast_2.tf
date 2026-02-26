resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_c104d4c172" {
  bucket                  = "audit-logs-af73-ap-northeast-2-17"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
