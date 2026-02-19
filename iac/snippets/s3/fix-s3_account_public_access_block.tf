resource "aws_s3_account_public_access_block" "fix_s3_account_public_access" {
  account_id              = var.account_id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
