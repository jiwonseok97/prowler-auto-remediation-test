resource "aws_s3_bucket_policy" "fix_config_bucket_policy_47960d952e" {
  bucket = "aws-config-logs-132410971304-eu-west-3"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-west-3:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-west-3:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3/AWSLogs/132410971304/Config/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304",
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:eu-west-3:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3"
    },
    {
      "Sid": "AWSConfigBucketListCheckAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3"
    },
    {
      "Sid": "AWSConfigBucketDeliveryAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-eu-west-3/AWSLogs/132410971304/Config/*"
    }
  ]
}
POLICY
}

resource "aws_config_configuration_recorder" "fix_config_recorder_47960d952e" {
  name     = "default"
  role_arn = "arn:aws:iam::132410971304:role/aws-service-role/config.amazonaws.com/AWSServiceRoleForConfig"

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

resource "aws_config_delivery_channel" "fix_config_delivery_channel_47960d952e" {
  name           = "default"
  s3_bucket_name = "aws-config-logs-132410971304-eu-west-3"
  depends_on     = [aws_s3_bucket_policy.fix_config_bucket_policy_47960d952e, aws_config_configuration_recorder.fix_config_recorder_47960d952e]
}

resource "aws_config_configuration_recorder_status" "fix_config_recorder_status_47960d952e" {
  name       = "default"
  is_enabled = true
  depends_on = [aws_config_delivery_channel.fix_config_delivery_channel_47960d952e]
}
