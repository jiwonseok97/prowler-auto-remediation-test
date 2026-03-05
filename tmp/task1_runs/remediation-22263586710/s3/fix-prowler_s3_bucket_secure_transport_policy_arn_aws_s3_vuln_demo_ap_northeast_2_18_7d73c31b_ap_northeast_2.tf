resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c372c121c2" {
  bucket = "vuln-demo-ap-northeast-2-18-7d73c31b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-7d73c31b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-7d73c31b/*"
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
