resource "aws_s3_bucket_policy" "fix_s3_secure_transport_05f030fca2" {
  bucket = "audit-logs-af73-ap-northeast-2-07"
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
        "arn:aws:s3:::audit-logs-af73-ap-northeast-2-07",
        "arn:aws:s3:::audit-logs-af73-ap-northeast-2-07/*"
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
