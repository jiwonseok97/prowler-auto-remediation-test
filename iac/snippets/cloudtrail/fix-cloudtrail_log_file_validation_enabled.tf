variable "cloudtrail_name" {
  type = string
}

resource "aws_cloudtrail" "fix_cloudtrail_validation" {
  name                          = var.cloudtrail_name
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true

  lifecycle {
    ignore_changes = [
      event_selector,
      insight_selector,
      kms_key_id,
      s3_bucket_name,
      s3_key_prefix,
      sns_topic_name,
      tags,
      tags_all
    ]
  }
}
