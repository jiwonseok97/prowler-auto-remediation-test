resource "aws_s3_bucket_policy" "fix_s3_secure_transport_3c37d411e9" {
  bucket = "vuln-demo-ap-northeast-2-16-bf3e48ec"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-bf3e48ec",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-bf3e48ec/*"
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
