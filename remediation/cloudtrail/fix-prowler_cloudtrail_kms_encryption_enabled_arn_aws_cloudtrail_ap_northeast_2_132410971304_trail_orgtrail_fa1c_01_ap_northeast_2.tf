resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_ff1ac972fa" {
  bucket = "trail-logs-fa1c-ap-northeast-2-01"
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
      "Resource": "arn:aws:s3:::trail-logs-fa1c-ap-northeast-2-01"
    },
    {
      "Sid": "AWSCloudTrailWrite",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::trail-logs-fa1c-ap-northeast-2-01/AWSLogs/132410971304/*",
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

resource "aws_kms_key" "fix_cloudtrail_kms_key_ff1ac972fa" {
  description         = "CloudTrail encryption key created by remediation"
  enable_key_rotation = true
  policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"EnableRootAndCallerPermissions\", \"Effect\": \"Allow\", \"Principal\": {\"AWS\": [\"arn:aws:iam::132410971304:root\", \"arn:aws:iam::132410971304:role/GitHubActionsProwlerRole\"]}, \"Action\": \"kms:*\", \"Resource\": \"*\"}, {\"Sid\": \"AllowCloudTrailUseOfTheKey\", \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": [\"kms:GenerateDataKey*\", \"kms:Decrypt\", \"kms:Encrypt\", \"kms:DescribeKey\"], \"Resource\": \"*\", \"Condition\": {\"StringEquals\": {\"aws:SourceArn\": \"arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/orgtrail-fa1c-01\"}}}]}"
}

resource "aws_iam_role" "fix_cloudtrail_cw_role_ff1ac972fa" {
  name               = "cloudtrail-to-cw-orgtrail_fa1c_01"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_ff1ac972fa" {
  name       = "cloudtrail-to-cloudwatch-logs"
  role       = "cloudtrail-to-cw-orgtrail_fa1c_01"
  policy     = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": [\"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*\", \"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304\"]}]}"
  depends_on = [aws_iam_role.fix_cloudtrail_cw_role_ff1ac972fa]
}

resource "aws_sns_topic" "fix_cloudtrail_sns_ff1ac972fa" {
  name = "cloudtrail-alerts-orgtrail_fa1c_01"
}

resource "aws_cloudtrail" "fix_cloudtrail_ff1ac972fa" {
  name                          = "orgtrail-fa1c-01"
  s3_bucket_name                = "trail-logs-fa1c-ap-northeast-2-01"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.fix_cloudtrail_kms_key_ff1ac972fa.arn
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = aws_iam_role.fix_cloudtrail_cw_role_ff1ac972fa.arn
  sns_topic_name                = aws_sns_topic.fix_cloudtrail_sns_ff1ac972fa.name

  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy_ff1ac972fa, aws_iam_role_policy.fix_cloudtrail_cw_role_policy_ff1ac972fa]

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
