resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_7c4faa3a00" {
  bucket = "trail-logs-af73-ap-northeast-2"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSCloudTrailAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::trail-logs-af73-ap-northeast-2"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::trail-logs-af73-ap-northeast-2/AWSLogs/132410971304/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role" "fix_cloudtrail_cw_role_7c4faa3a00" {
  name               = "remediation_ct_cw_orgtrail_af73"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_7c4faa3a00" {
  name       = "cloudtrail-to-cloudwatch-logs"
  role       = "remediation_ct_cw_orgtrail_af73"
  policy     = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": [\"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*\", \"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304\"]}]}"
  depends_on = [aws_iam_role.fix_cloudtrail_cw_role_7c4faa3a00]
}

resource "aws_cloudtrail" "fix_cloudtrail_7c4faa3a00" {
  name                          = "orgtrail-af73"
  s3_bucket_name                = "trail-logs-af73-ap-northeast-2"
  include_global_service_events = true
  is_multi_region_trail         = false
  enable_logging                = true
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = aws_iam_role.fix_cloudtrail_cw_role_7c4faa3a00.arn
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy_7c4faa3a00, aws_iam_role_policy.fix_cloudtrail_cw_role_policy_7c4faa3a00]

  lifecycle {
    ignore_changes = [
      insight_selector,
      sns_topic_name,
      tags,
      tags_all,
      event_selector,
      advanced_event_selector,
      kms_key_id
    ]
  }
}
