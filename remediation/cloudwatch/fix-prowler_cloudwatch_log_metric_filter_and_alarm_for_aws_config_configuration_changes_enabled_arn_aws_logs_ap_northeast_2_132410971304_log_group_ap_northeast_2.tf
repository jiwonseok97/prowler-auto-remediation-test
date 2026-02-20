resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_9e89640bb9" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_9e89640bb9" {
  name           = "filter-cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventSource = \"config.amazonaws.com\") && (($.eventName = \"StopConfigurationRecorder\") || ($.eventName = \"DeleteDeliveryChannel\") || ($.eventName = \"PutDeliveryChannel\") || ($.eventName = \"PutConfigurationRecorder\")) }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_9e89640bb9]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_9e89640bb9" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_and_alarm_for_aws_config_configuration_changes_enabled"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
