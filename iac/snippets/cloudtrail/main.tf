# CloudTrail remediation snippet
resource "aws_cloudtrail" "secure_trail" {
  name                          = "secure-trail"
  s3_bucket_name                = "REPLACE_TRAIL_BUCKET"
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
}
