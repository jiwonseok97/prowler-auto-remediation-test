resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_0c377b8ecd" {
  bucket                  = "audit-logs-af73-ap-northeast-2-02"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
