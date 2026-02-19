resource "aws_cloudtrail" "fix_cloudtrail_kms" {
  name                          = var.cloudtrail_name
  enable_logging                = true
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_log_file_validation    = true
  kms_key_id                    = var.kms_key_arn

  lifecycle {
    ignore_changes = [
      event_selector,
      insight_selector,
      s3_bucket_name,
      s3_key_prefix,
      sns_topic_name,
      tags,
      tags_all
    ]
  }
}
