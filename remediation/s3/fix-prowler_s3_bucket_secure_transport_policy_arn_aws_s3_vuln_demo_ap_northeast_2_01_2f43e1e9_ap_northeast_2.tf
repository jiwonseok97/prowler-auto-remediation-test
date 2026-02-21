resource "aws_s3_bucket_policy" "fix_s3_secure_transport_dea2e47419" {
  bucket = "vuln-demo-ap-northeast-2-01-2f43e1e9"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-2f43e1e9",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-2f43e1e9/*"
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
