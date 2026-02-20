resource "aws_s3_bucket_policy" "fix_s3_secure_transport_7188fffd85" {
  bucket = "aws-config-logs-132410971304-ap-southeast-2"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:ap-southeast-2:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:ap-southeast-2:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2/AWSLogs/132410971304/Config/*",
      "Condition": {
        "StringEquals": {
          "aws:SourceAccount": "132410971304",
          "s3:x-amz-acl": "bucket-owner-full-control"
        },
        "ArnLike": {
          "aws:SourceArn": "arn:aws:config:ap-southeast-2:132410971304:*"
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
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2"
    },
    {
      "Sid": "AWSConfigBucketListCheckAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2"
    },
    {
      "Sid": "AWSConfigBucketDeliveryAllow",
      "Effect": "Allow",
      "Principal": {
        "Service": "config.amazonaws.com"
      },
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2/AWSLogs/132410971304/Config/*"
    },
    {
      "Sid": "DenyInsecureTransport",
      "Effect": "Deny",
      "Principal": "*",
      "Action": "s3:*",
      "Resource": [
        "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2",
        "arn:aws:s3:::aws-config-logs-132410971304-ap-southeast-2/*"
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
