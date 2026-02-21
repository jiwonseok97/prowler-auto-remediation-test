resource "aws_s3_bucket_policy" "fix_s3_secure_transport_1627db6c9f" {
  bucket = "vuln-demo-ap-northeast-2-05-26cf376b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-26cf376b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-26cf376b/*"
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
