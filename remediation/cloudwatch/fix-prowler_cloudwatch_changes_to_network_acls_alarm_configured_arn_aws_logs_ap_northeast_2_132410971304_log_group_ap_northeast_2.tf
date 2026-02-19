resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_db3516d94b" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_db3516d94b" {
  name           = "filter-cloudwatch_changes_to_network_acls_alarm_configured"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventName = \"CreateNetworkAcl\") || ($.eventName = \"CreateNetworkAclEntry\") || ($.eventName = \"DeleteNetworkAcl\") || ($.eventName = \"DeleteNetworkAclEntry\") || ($.eventName = \"ReplaceNetworkAclEntry\") || ($.eventName = \"ReplaceNetworkAclAssociation\") }"

  metric_transformation {
    name      = "cloudwatch_changes_to_network_acls_alarm_configured"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_db3516d94b]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_db3516d94b" {
  alarm_name          = "alarm-cloudwatch_changes_to_network_acls_alarm_configured"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_changes_to_network_acls_alarm_configured"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
