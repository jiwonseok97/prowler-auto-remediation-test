resource "aws_s3_bucket_policy" "fix_s3_secure_transport_9f0fd28ce7" {
  bucket = "vuln-demo-ap-northeast-2-22-26002822"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-22-26002822",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-22-26002822/*"
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
