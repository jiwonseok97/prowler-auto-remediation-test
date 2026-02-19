resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_e3a40ad51d" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_e3a40ad51d" {
  name           = "filter-cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventName = \"CreateTrail\") || ($.eventName = \"UpdateTrail\") || ($.eventName = \"DeleteTrail\") || ($.eventName = \"StartLogging\") || ($.eventName = \"StopLogging\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_e3a40ad51d]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_e3a40ad51d" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_and_alarm_for_cloudtrail_configuration_changes_enabled"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
