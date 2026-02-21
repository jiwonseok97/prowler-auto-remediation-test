resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_cdda5d6ebc" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_cdda5d6ebc" {
  name           = "filter-cloudwatch_log_metric_filter_sign_in_without_mfa"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.additionalEventData.MFAUsed != \"Yes\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_sign_in_without_mfa"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_cdda5d6ebc]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_cdda5d6ebc" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_sign_in_without_mfa"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_sign_in_without_mfa"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
