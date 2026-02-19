resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_f3b6ffaa1d" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_f3b6ffaa1d" {
  name           = "filter-cloudwatch_log_metric_filter_for_s3_bucket_policy_changes"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventSource = \"s3.amazonaws.com\") && (($.eventName = \"PutBucketAcl\") || ($.eventName = \"PutBucketPolicy\") || ($.eventName = \"PutBucketCors\") || ($.eventName = \"PutBucketLifecycle\") || ($.eventName = \"PutBucketReplication\") || ($.eventName = \"DeleteBucketPolicy\") || ($.eventName = \"DeleteBucketCors\") || ($.eventName = \"DeleteBucketLifecycle\") || ($.eventName = \"DeleteBucketReplication\")) }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_for_s3_bucket_policy_changes"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_f3b6ffaa1d]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_f3b6ffaa1d" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_for_s3_bucket_policy_changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_for_s3_bucket_policy_changes"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
