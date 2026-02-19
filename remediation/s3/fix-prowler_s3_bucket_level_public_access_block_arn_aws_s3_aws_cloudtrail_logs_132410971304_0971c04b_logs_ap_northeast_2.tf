resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_3f06a52d3c" {
  bucket                  = "aws-cloudtrail-logs-132410971304-0971c04b-logs"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
