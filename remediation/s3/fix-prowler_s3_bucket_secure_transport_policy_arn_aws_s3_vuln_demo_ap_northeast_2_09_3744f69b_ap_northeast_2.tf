resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d39259843a" {
  bucket = "vuln-demo-ap-northeast-2-09-3744f69b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-3744f69b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-3744f69b/*"
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
