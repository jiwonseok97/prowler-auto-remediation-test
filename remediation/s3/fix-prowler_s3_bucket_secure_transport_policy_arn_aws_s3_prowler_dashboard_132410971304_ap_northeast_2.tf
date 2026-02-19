resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_02a8c829a9" {
  bucket                  = "prowler-dashboard-132410971304"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
