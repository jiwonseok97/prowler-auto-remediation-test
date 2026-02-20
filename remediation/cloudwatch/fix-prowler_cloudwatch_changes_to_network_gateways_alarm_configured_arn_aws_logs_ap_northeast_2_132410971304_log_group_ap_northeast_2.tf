resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_0a857cfc28" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_0a857cfc28" {
  name           = "filter-cloudwatch_changes_to_network_gateways_alarm_configured"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventName = \"CreateCustomerGateway\") || ($.eventName = \"DeleteCustomerGateway\") || ($.eventName = \"AttachInternetGateway\") || ($.eventName = \"CreateInternetGateway\") || ($.eventName = \"DeleteInternetGateway\") || ($.eventName = \"DetachInternetGateway\") }"

  metric_transformation {
    name      = "cloudwatch_changes_to_network_gateways_alarm_configured"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_0a857cfc28]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_0a857cfc28" {
  alarm_name          = "alarm-cloudwatch_changes_to_network_gateways_alarm_configured"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_changes_to_network_gateways_alarm_configured"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
