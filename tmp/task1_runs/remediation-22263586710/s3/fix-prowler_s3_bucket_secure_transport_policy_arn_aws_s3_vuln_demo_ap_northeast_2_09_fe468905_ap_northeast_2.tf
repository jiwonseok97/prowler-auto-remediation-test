resource "aws_s3_bucket_policy" "fix_s3_secure_transport_7d614c6f88" {
  bucket = "vuln-demo-ap-northeast-2-09-fe468905"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-fe468905",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-fe468905/*"
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
