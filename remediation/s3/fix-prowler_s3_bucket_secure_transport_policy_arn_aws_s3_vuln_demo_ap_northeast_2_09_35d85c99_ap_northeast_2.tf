resource "aws_s3_bucket_policy" "fix_s3_secure_transport_54a13c0cf0" {
  bucket = "vuln-demo-ap-northeast-2-09-35d85c99"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-35d85c99",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-35d85c99/*"
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
