resource "aws_s3_bucket_policy" "fix_s3_secure_transport_af9b9f3b88" {
  bucket = "vuln-demo-ap-northeast-2-15-faf1c038"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-15-faf1c038",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-15-faf1c038/*"
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
