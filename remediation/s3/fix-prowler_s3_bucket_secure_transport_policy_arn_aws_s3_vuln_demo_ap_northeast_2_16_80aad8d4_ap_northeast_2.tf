resource "aws_s3_bucket_policy" "fix_s3_secure_transport_29158e11fc" {
  bucket = "vuln-demo-ap-northeast-2-16-80aad8d4"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-80aad8d4",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-80aad8d4/*"
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
