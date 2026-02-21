resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_176efa0407" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_176efa0407" {
  name           = "filter-cloudwatch_log_metric_filter_root_usage"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.userIdentity.type = \"Root\") && ($.userIdentity.invokedBy NOT EXISTS) && ($.eventType != \"AwsServiceEvent\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_root_usage"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_176efa0407]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_176efa0407" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_root_usage"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_root_usage"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
