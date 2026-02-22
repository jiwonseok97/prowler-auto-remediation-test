resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ad85884c00" {
  bucket = "vuln-demo-ap-northeast-2-08-adf7236b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-adf7236b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-adf7236b/*"
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
