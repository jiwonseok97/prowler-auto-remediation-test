resource "aws_s3_bucket_public_access_block" "fix_s3_public_access_9509dc40ad" {
  bucket                  = "vuln-bucket-ap-northeast-2-9c753e89"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
