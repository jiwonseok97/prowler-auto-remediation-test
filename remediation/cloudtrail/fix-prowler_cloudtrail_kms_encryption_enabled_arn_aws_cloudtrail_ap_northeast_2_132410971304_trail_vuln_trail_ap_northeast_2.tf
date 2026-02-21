resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_19040a1c46" {
  bucket = "vuln-cloudtrail-ap-northeast-2-f9fd7730"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730",
        "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    },
    {
      "Sid": "AWSCloudTrailAclCheck20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/vuln-trail"
        }
      }
    },
    {
      "Sid": "AWSCloudTrailWrite20150319",
      "Effect": "Allow",
      "Principal": {
        "Service": "cloudtrail.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730/AWSLogs/132410971304/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/vuln-trail",
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_kms_key" "fix_cloudtrail_kms_key_19040a1c46" {
  description         = "CloudTrail encryption key created by remediation"
  enable_key_rotation = true
  policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"EnableRootPermissions\", \"Effect\": \"Allow\", \"Principal\": {\"AWS\": \"arn:aws:iam::132410971304:root\"}, \"Action\": \"kms:*\", \"Resource\": \"*\"}, {\"Sid\": \"AllowCloudTrailUseOfTheKey\", \"Effect\": \"Allow\", \"Principal\": {\"Service\": \"cloudtrail.amazonaws.com\"}, \"Action\": [\"kms:GenerateDataKey*\", \"kms:Decrypt\", \"kms:Encrypt\", \"kms:DescribeKey\"], \"Resource\": \"*\", \"Condition\": {\"StringEquals\": {\"aws:SourceArn\": \"arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/vuln-trail\"}}}]}"
}

resource "aws_cloudtrail" "fix_cloudtrail_19040a1c46" {
  name                          = "vuln-trail"
  s3_bucket_name                = "vuln-cloudtrail-ap-northeast-2-f9fd7730"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true
  kms_key_id                    = aws_kms_key.fix_cloudtrail_kms_key_19040a1c46.arn
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = "arn:aws:iam::132410971304:role/cloudtrail-to-cw-vuln_trail"

  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy_19040a1c46]

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
