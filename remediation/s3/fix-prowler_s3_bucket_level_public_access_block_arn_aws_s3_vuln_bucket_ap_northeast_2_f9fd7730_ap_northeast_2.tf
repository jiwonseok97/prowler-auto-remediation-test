resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_d403de7ba9" {
  bucket                  = "vuln-bucket-ap-northeast-2-f9fd7730"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
