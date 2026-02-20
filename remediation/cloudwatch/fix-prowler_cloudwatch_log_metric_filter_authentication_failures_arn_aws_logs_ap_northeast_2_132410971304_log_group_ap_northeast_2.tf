resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_543ac38aa1" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_543ac38aa1" {
  name           = "filter-cloudwatch_log_metric_filter_authentication_failures"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventName = \"ConsoleLogin\") && ($.errorMessage = \"Failed authentication\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_authentication_failures"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_543ac38aa1]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_543ac38aa1" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_authentication_failures"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_authentication_failures"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
