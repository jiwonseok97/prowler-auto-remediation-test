resource "aws_s3_bucket_policy" "fix_config_bucket_policy_b2c3c85345" {
  bucket = "aws-config-logs-132410971304-eu-central-1"
  policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "AWSConfigBucketAclCheck",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-central-1:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-central-1:132410971304:*"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketDelivery",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1/AWSLogs/132410971304/Config/*",
      "Condition": {
        "StringEquals": {
          "s3:x-amz-acl": "bucket-owner-full-control",
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-central-1:132410971304:*"
        }
      }
    },
    {
      "Sid": "AWSConfigBucketAclCheckAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:GetBucketAcl",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1"
    },
    {
      "Sid": "AWSConfigBucketListCheckAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1"
    },
    {
      "Sid": "AWSConfigBucketDeliveryAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1/AWSLogs/132410971304/Config/*"
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1",
        "arn:aws:s3:::aws-config-logs-132410971304-eu-central-1/*"
      ],
      "Condition": {
        "Bool": {
          "aws:SecureTransport": "false"
        }
      }
    }
  ]
}
POLICY
}

resource "aws_config_configuration_recorder" "fix_config_recorder_b2c3c85345" {
  name     = "default"
  role_arn = "arn:aws:iam::132410971304:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "fix_config_delivery_channel_b2c3c85345" {
  name           = "default"
  s3_bucket_name = "aws-config-logs-132410971304-eu-central-1"
  depends_on     = [aws_s3_bucket_policy.fix_config_bucket_policy_b2c3c85345, aws_config_configuration_recorder.fix_config_recorder_b2c3c85345]
}

resource "aws_config_configuration_recorder_status" "fix_config_recorder_status_b2c3c85345" {
  name       = "default"
  is_enabled = true
  depends_on = [aws_config_delivery_channel.fix_config_delivery_channel_b2c3c85345]
}
