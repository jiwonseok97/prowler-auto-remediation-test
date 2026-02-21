resource "aws_s3_bucket_policy" "fix_s3_secure_transport_65eee060dd" {
  bucket = "vuln-demo-ap-northeast-2-32-6c108957"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-32-6c108957",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-32-6c108957/*"
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
