variable "bucket_name" {
  type = string
}

resource "aws_s3_bucket_versioning" "fix_s3_bucket_versioning" {
  bucket = var.bucket_name

  versioning_configuration {
    status = "Enabled"
  }
}
