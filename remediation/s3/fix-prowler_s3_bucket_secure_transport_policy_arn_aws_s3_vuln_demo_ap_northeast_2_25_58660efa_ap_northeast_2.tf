resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e90d0e0492" {
  bucket = "vuln-demo-ap-northeast-2-25-58660efa"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-25-58660efa",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-25-58660efa/*"
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
