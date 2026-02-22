resource "aws_s3_bucket_policy" "fix_s3_secure_transport_7a2244a434" {
  bucket = "vuln-demo-ap-northeast-2-17-94389cac"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-94389cac",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-94389cac/*"
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
