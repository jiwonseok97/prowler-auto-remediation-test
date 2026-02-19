resource "aws_cloudtrail" "fix_cloudtrail_2b497faa04" {
  name                          = "vuln-trail"
  s3_bucket_name                = "vuln-cloudtrail-ap-northeast-2-f9fd7730"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

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
