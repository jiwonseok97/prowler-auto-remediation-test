resource "aws_s3_bucket_policy" "fix_s3_secure_transport_794a7d0eeb" {
  bucket = "vuln-demo-ap-northeast-2-12-df06fb8d"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-df06fb8d",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-df06fb8d/*"
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
