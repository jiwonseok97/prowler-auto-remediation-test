resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_df9b961ffd" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_df9b961ffd" {
  name           = "filter-cloudwatch_changes_to_vpcs_alarm_configured"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventName = \"CreateVpc\") || ($.eventName = \"DeleteVpc\") || ($.eventName = \"ModifyVpcAttribute\") || ($.eventName = \"AcceptVpcPeeringConnection\") || ($.eventName = \"CreateVpcPeeringConnection\") || ($.eventName = \"DeleteVpcPeeringConnection\") || ($.eventName = \"RejectVpcPeeringConnection\") || ($.eventName = \"AttachClassicLinkVpc\") || ($.eventName = \"DetachClassicLinkVpc\") || ($.eventName = \"DisableVpcClassicLink\") || ($.eventName = \"EnableVpcClassicLink\") }"

  metric_transformation {
    name      = "cloudwatch_changes_to_vpcs_alarm_configured"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_df9b961ffd]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_df9b961ffd" {
  alarm_name          = "alarm-cloudwatch_changes_to_vpcs_alarm_configured"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_changes_to_vpcs_alarm_configured"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
