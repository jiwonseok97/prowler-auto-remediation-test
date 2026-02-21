resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d9ee1256ff" {
  bucket = "vuln-demo-ap-northeast-2-18-e2a16d5c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-e2a16d5c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-e2a16d5c/*"
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
