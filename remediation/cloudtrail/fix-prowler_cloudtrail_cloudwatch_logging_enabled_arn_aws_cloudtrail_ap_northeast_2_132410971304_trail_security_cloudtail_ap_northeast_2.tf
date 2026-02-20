resource "aws_iam_role" "fix_cloudtrail_cw_role_41c4cc5c5c" {
  name               = "cloudtrail-to-cw-security_cloudtail"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_41c4cc5c5c" {
  name   = "cloudtrail-to-cloudwatch-logs"
  role   = "cloudtrail-to-cw-security_cloudtail"
  policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": [\"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*\", \"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304\"]}]}"
}

resource "aws_cloudtrail" "fix_cloudtrail_41c4cc5c5c" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = aws_iam_role.fix_cloudtrail_cw_role_41c4cc5c5c.arn
  enable_log_file_validation    = true

  depends_on = [aws_iam_role_policy.fix_cloudtrail_cw_role_policy_41c4cc5c5c]

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
