resource "aws_s3_bucket_policy" "fix_s3_secure_transport_fb3049e35e" {
  bucket = "vuln-demo-ap-northeast-2-03-f26f1aed"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-f26f1aed",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-f26f1aed/*"
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
