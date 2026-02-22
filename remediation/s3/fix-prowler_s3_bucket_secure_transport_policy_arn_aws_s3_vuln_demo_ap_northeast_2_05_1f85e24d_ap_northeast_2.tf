resource "aws_s3_bucket_policy" "fix_s3_secure_transport_8f9c5709c6" {
  bucket = "vuln-demo-ap-northeast-2-05-1f85e24d"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-1f85e24d",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-1f85e24d/*"
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
