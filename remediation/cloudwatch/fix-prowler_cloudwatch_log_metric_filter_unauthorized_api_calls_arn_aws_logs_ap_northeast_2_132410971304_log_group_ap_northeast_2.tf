resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_efe1ac2907" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_efe1ac2907" {
  name           = "filter-cloudwatch_log_metric_filter_unauthorized_api_calls"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.errorCode = \"*UnauthorizedOperation\") || ($.errorCode = \"AccessDenied*\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_unauthorized_api_calls"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_efe1ac2907]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_efe1ac2907" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_unauthorized_api_calls"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_unauthorized_api_calls"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
