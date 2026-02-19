variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket_server_side_encryption_configuration" "fix_s3_encryption" {
  bucket = var.bucket_name

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
