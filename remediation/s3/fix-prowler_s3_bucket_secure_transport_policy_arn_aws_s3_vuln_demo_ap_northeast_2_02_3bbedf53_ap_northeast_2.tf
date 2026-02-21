resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f46bb5a849" {
  bucket = "vuln-demo-ap-northeast-2-02-3bbedf53"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-3bbedf53",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-3bbedf53/*"
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
