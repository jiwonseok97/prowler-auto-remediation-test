resource "aws_cloudtrail" "fix_cloudtrail_e5d0c3fe3f" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

  lifecycle {
    ignore_changes = [
      event_selector,
      insight_selector,
      sns_topic_name,
      tags,
      tags_all
    ]
  }
}
