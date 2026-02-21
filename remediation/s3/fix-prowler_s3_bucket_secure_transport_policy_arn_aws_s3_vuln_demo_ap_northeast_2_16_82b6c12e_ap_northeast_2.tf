resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0f24d35f5e" {
  bucket = "vuln-demo-ap-northeast-2-16-82b6c12e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-82b6c12e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-82b6c12e/*"
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
