resource "aws_cloudwatch_log_group" "fix_cloudwatch_log_group_e24a9da00e" {
  name = "ap-northeast-2"
}

resource "aws_cloudwatch_log_metric_filter" "fix_cloudwatch_metric_filter_e24a9da00e" {
  name           = "filter-cloudwatch_log_metric_filter_policy_changes"
  log_group_name = "ap-northeast-2"
  pattern        = "{ ($.eventName = \"DeleteGroupPolicy\") || ($.eventName = \"DeleteRolePolicy\") || ($.eventName = \"DeleteUserPolicy\") || ($.eventName = \"PutGroupPolicy\") || ($.eventName = \"PutRolePolicy\") || ($.eventName = \"PutUserPolicy\") || ($.eventName = \"CreatePolicy\") || ($.eventName = \"DeletePolicy\") || ($.eventName = \"CreatePolicyVersion\") || ($.eventName = \"DeletePolicyVersion\") || ($.eventName = \"AttachRolePolicy\") || ($.eventName = \"DetachRolePolicy\") || ($.eventName = \"AttachUserPolicy\") || ($.eventName = \"DetachUserPolicy\") || ($.eventName = \"AttachGroupPolicy\") || ($.eventName = \"DetachGroupPolicy\") }"

  metric_transformation {
    name      = "cloudwatch_log_metric_filter_policy_changes"
    namespace = "CISBenchmark"
    value     = "1"
  }
  depends_on = [aws_cloudwatch_log_group.fix_cloudwatch_log_group_e24a9da00e]
}

resource "aws_cloudwatch_metric_alarm" "fix_cloudwatch_metric_alarm_e24a9da00e" {
  alarm_name          = "alarm-cloudwatch_log_metric_filter_policy_changes"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "cloudwatch_log_metric_filter_policy_changes"
  namespace           = "CISBenchmark"
  period              = 300
  statistic           = "Sum"
  threshold           = 1
  alarm_description   = "Auto-generated remediation alarm"
}
