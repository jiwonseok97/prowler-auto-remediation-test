resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f809b6ae3e" {
  bucket = "vuln-demo-ap-northeast-2-17-8590e2ae"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-8590e2ae",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-8590e2ae/*"
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
