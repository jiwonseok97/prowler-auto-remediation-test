resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_db192a6de6" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_db192a6de6" {
  name           = "filter-cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventSource = \"kms.amazonaws.com\") && (($.eventName = \"DisableKey\") || ($.eventName = \"ScheduleKeyDeletion\")) }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_db192a6de6]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_db192a6de6" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_disable_or_scheduled_deletion_of_kms_cmk"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
