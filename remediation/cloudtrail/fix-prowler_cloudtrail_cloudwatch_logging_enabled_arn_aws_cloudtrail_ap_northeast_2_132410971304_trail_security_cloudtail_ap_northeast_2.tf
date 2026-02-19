resource "aws_cloudwatch_log_group" "fix_cloudtrail_log_group_41c4cc5c5c" {
  name = "/aws/cloudtrail/132410971304"
}

resource "aws_iam_role" "fix_cloudtrail_cw_role_41c4cc5c5c" {
  name               = "CloudTrail_CloudWatchLogs_Role_security_cloudtail"
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_41c4cc5c5c" {
  name   = "CloudTrail_CloudWatchLogs_Role_security_cloudtail-policy"
  role   = aws_iam_role.fix_cloudtrail_cw_role_41c4cc5c5c.id
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": [
        "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:log-stream:*",
        "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
      ]
    }
  ]
}
POLICY
}

resource "aws_cloudtrail" "fix_cloudtrail_41c4cc5c5c" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = "arn:aws:iam::132410971304:role/CloudTrail_CloudWatchLogs_Role_security_cloudtail"

  lifecycle {
    ignore_changes = [
      event_selector,
      insight_selector,
      sns_topic_name,
      tags,
      tags_all
    ]
  }
}
