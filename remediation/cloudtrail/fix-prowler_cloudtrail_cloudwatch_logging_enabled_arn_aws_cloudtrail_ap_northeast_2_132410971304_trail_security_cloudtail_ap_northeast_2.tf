resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_41c4cc5c5c" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "1",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*",
      "Condition": {
        "StringNotEquals": {
          "s3:x-amz-server-side-encryption": "aws:kms"
        }
      }
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
        "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/*"
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
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/security-cloudtail"
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
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/AWSLogs/132410971304/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceArn": "arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/security-cloudtail",
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryWrite1",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/AWSLogs/132410971304/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304",
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:logs:ap-northeast-2:132410971304:*"
        }
      }
    },
    {
      "Sid": "AWSLogDeliveryAclCheck1",
      "Effect": "Allow",
      "Principal": {
        "Service": "delivery.logs.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:logs:ap-northeast-2:132410971304:*"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b"
    },
    {
      "Sid": "AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/AWSLogs/132410971304/Config/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketListCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:ap-northeast-2:132410971304:*"
        }
      }
    },
    {
      "Sid": "S3ServerAccessLogsPolicy",
      "Effect": "Allow",
      "Principal": {
        "Service": "logging.s3.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b/s3-access-logs/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "fix_cloudtrail_cw_role_policy_41c4cc5c5c" {
  name   = "cloudtrail-to-cloudwatch-logs"
  role   = "cloudtrail-to-cw-security_cloudtail"
  policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Action\": [\"logs:CreateLogStream\", \"logs:PutLogEvents\"], \"Resource\": [\"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*\", \"arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304\"]}]}"
}

resource "aws_cloudtrail" "fix_cloudtrail_41c4cc5c5c" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  cloud_watch_logs_group_arn    = "arn:aws:logs:ap-northeast-2:132410971304:log-group:/aws/cloudtrail/132410971304:*"
  cloud_watch_logs_role_arn     = "arn:aws:iam::132410971304:role/cloudtrail-to-cw-security_cloudtail"
  enable_log_file_validation    = true

  depends_on = [aws_s3_bucket_policy.fix_cloudtrail_bucket_policy_41c4cc5c5c, aws_iam_role_policy.fix_cloudtrail_cw_role_policy_41c4cc5c5c]

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
