resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_fdc9193d99" {
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

resource "aws_kms_key" "fix_cloudtrail_kms_key_fdc9193d99" {
  description         = "CloudTrail encryption key created by remediation"
  enable_key_rotation = true
  policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"EnableRootAndCallerPermissions\", \"Effect\": \"Allow\", \"Principal\": {\"AWS\": [\"arn:aws:iam::132410971304:root\", \"arn:aws:iam::132410971304:role/GitHubActionsProwlerRole\"]}, \"Action\": \"kms:*\", \"Resource\": \"*\"}, {\"Sid\": \"AllowCloudTrailUseOfTheKey\", \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": [\"kms:GenerateDataKey*\", \"kms:Decrypt\", \"kms:Encrypt\", \"kms:DescribeKey\"], \"Resource\": \"*\", \"Condition\": {\"StringEquals\": {\"aws:SourceArn\": \"arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/orgtrail-af73\"}}}]}"
}

resource "aws_iam_role" "fix_cloudtrail_cw_role_fdc9193d99" {
  name               = "cloudtrail-to-cw-orgtrail_af73"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_fdc9193d99" {
  name       = "cloudtrail-to-cloudwatch-logs"
  role       = "cloudtrail-to-cw-orgtrail_af73"
  policy     = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": [\"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*\", \"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304\"]}]}"
  depends_on = [aws_iam_role.fix_cloudtrail_cw_role_fdc9193d99]
}

resource "aws_sns_topic" "fix_cloudtrail_sns_fdc9193d99" {
  name = "cloudtrail-alerts-orgtrail_af73"
}

resource "aws_cloudtrail" "fix_cloudtrail_fdc9193d99" {
  name                          = "orgtrail-af73"
  s3_bucket_name                = "trail-logs-af73-ap-northeast-2"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.fix_cloudtrail_kms_key_fdc9193d99.arn
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = aws_iam_role.fix_cloudtrail_cw_role_fdc9193d99.arn
  sns_topic_name                = aws_sns_topic.fix_cloudtrail_sns_fdc9193d99.name

  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy_fdc9193d99, aws_iam_role_policy.fix_cloudtrail_cw_role_policy_fdc9193d99]

  lifecycle {
    ignore_changes = [
      insight_selector,
      sns_topic_name,
      tags,
      tags_all,
      event_selector,
      advanced_event_selector
    ]
  }
}
