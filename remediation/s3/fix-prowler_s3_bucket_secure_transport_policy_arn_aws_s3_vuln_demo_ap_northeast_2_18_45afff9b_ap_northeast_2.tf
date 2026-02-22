resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c8168d34c6" {
  bucket = "vuln-demo-ap-northeast-2-18-45afff9b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-45afff9b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-45afff9b/*"
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
