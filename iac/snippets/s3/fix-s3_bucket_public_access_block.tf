variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket_public_access_block" "fix_s3_public_access" {
  bucket                  = var.bucket_name
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
