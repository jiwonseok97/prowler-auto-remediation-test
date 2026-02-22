resource "aws_s3_bucket_policy" "fix_s3_secure_transport_6bd2a36fb4" {
  bucket = "vuln-demo-ap-northeast-2-16-91016d95"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-91016d95",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-91016d95/*"
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
