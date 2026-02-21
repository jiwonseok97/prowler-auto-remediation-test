resource "aws_s3_bucket_policy" "fix_s3_secure_transport_4ac08e018a" {
  bucket = "vuln-demo-ap-northeast-2-24-bd586b3b"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-24-bd586b3b",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-24-bd586b3b/*"
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
