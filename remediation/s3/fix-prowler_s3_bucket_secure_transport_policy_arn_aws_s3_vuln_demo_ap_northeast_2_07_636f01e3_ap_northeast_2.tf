resource "aws_s3_bucket_policy" "fix_s3_secure_transport_04ae11388c" {
  bucket = "vuln-demo-ap-northeast-2-07-636f01e3"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-636f01e3",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-636f01e3/*"
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
