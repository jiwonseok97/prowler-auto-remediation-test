resource "aws_s3_bucket_policy" "fix_s3_secure_transport_7060a4c626" {
  bucket = "vuln-demo-ap-northeast-2-19-2ea0a119"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-2ea0a119",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-2ea0a119/*"
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
