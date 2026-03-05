resource "aws_s3_bucket_policy" "fix_s3_secure_transport_56c6db6b48" {
  bucket = "vuln-demo-ap-northeast-2-19-7b671e5a"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-7b671e5a",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-7b671e5a/*"
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
