resource "aws_s3_bucket_policy" "fix_cloudtrail_bucket_policy_21ff33774c" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
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
    }
  ]
}
POLICY
}

resource "aws_cloudtrail" "fix_cloudtrail_21ff33774c" {
  name                          = "security-cloudtail"
  s3_bucket_name                = "aws-cloudtrail-logs-132410971304-0971c04b"
  include_global_service_events = true
  is_multi_region_trail         = true
  enable_logging                = true
  enable_log_file_validation    = true

  event_selector {
    read_write_type           = "All"
    include_management_events = true

    data_resource {
      type   = "AWS::S3::Object"
      values = ["arn:aws:s3:::"]
    }
  }

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
