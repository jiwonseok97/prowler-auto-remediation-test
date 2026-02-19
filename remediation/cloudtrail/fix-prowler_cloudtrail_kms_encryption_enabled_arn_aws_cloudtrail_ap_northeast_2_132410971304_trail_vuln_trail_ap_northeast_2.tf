resource "aws_kms_key" "fix_cloudtrail_kms_key_19040a1c46" {
  description         = "CloudTrail encryption key created by remediation"
  enable_key_rotation = true
}

resource "aws_kms_alias" "fix_cloudtrail_kms_alias_19040a1c46" {
  name          = "alias/cloudtrail-remediation-vuln_trail"
  target_key_id = aws_kms_key.fix_cloudtrail_kms_key_19040a1c46.key_id
}

resource "aws_cloudtrail" "fix_cloudtrail_19040a1c46" {
  name                          = "vuln-trail"
  s3_bucket_name                = "vuln-cloudtrail-ap-northeast-2-f9fd7730"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.fix_cloudtrail_kms_key_19040a1c46.arn

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
