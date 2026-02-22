resource "aws_s3_bucket_policy" "fix_s3_secure_transport_a7104c4e0e" {
  bucket = "vuln-demo-ap-northeast-2-20-a2ac9d0a"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-a2ac9d0a",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-a2ac9d0a/*"
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
