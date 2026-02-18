# S3 remediation snippet
resource "aws_s3_bucket_public_access_block" "secure_bucket" {
  bucket                  = "REPLACE_BUCKET_ID"
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_bucket" {
  bucket = "REPLACE_BUCKET_ID"

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
