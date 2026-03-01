resource "aws_s3_bucket_policy" "fix_cloudtrail_accesslog_target_policy_a5e59ad078" {
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
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceArn": "arn:aws:cloudtrail:ap-northeast-2:132410971304:trail/security-cloudtail"
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
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceAccount": "132410971304"
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

resource "aws_s3_bucket_logging" "fix_cloudtrail_bucket_logging_a5e59ad078" {
  bucket        = "trail-logs-2c03-ap-northeast-2-02"
  target_bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  target_prefix = "s3-access-logs/"
  depends_on    = [aws_s3_bucket_policy.fix_cloudtrail_accesslog_target_policy_a5e59ad078]
}
