resource "aws_s3_bucket_policy" "fix_s3_secure_transport_8709976bed" {
  bucket = "vuln-demo-ap-northeast-2-30-ea71a53e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-ea71a53e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-ea71a53e/*"
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
