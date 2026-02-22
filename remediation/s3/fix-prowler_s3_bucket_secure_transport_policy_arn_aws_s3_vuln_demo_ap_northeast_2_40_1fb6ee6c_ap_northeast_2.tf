resource "aws_s3_bucket_policy" "fix_s3_secure_transport_fa2dfe3050" {
  bucket = "vuln-demo-ap-northeast-2-40-1fb6ee6c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-1fb6ee6c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-1fb6ee6c/*"
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
