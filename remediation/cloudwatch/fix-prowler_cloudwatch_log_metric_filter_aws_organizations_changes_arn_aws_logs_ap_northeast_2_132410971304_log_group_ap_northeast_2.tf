resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_3a632f4b4d" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_3a632f4b4d" {
  name           = "filter-cloudwatch_log_metric_filter_aws_organizations_changes"
  log_group_name = "/aws/cloudtrail/132410971304"
  pattern        = "{ ($.eventSource = \"organizations.amazonaws.com\") && (($.eventName = \"AcceptHandshake\") || ($.eventName = \"AttachPolicy\") || ($.eventName = \"CancelHandshake\") || ($.eventName = \"CreateAccount\") || ($.eventName = \"CreateOrganization\") || ($.eventName = \"CreateOrganizationalUnit\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeclineHandshake\") || ($.eventName = \"DeleteOrganization\") || ($.eventName = \"DeleteOrganizationalUnit\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"EnableAllFeatures\") || ($.eventName = \"EnablePolicyType\") || ($.eventName = \"InviteAccountToOrganization\") || ($.eventName = \"LeaveOrganization\") || ($.eventName = \"DetachPolicy\") || ($.eventName = \"DisablePolicyType\") || ($.eventName = \"MoveAccount\") || ($.eventName = \"RemoveAccountFromOrganization\") || ($.eventName = \"UpdateOrganizationalUnit\") || ($.eventName = \"UpdatePolicy\")) }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_aws_organizations_changes"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_3a632f4b4d]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_3a632f4b4d" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_aws_organizations_changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_aws_organizations_changes"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
