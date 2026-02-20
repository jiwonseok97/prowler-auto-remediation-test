resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_42d1a23b38" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_42d1a23b38" {
  name           = "filter-cloudwatch_log_metric_filter_security_group_changes"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventName = \"AuthorizeSecurityGroupIngress\") || ($.eventName = \"AuthorizeSecurityGroupEgress\") || ($.eventName = \"RevokeSecurityGroupIngress\") || ($.eventName = \"RevokeSecurityGroupEgress\") || ($.eventName = \"CreateSecurityGroup\") || ($.eventName = \"DeleteSecurityGroup\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_security_group_changes"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_42d1a23b38]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_42d1a23b38" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_security_group_changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_security_group_changes"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
