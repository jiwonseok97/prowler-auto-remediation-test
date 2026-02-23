resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d9a9c6be57" {
  bucket = "vuln-demo-123456789012-ap-northeast-2-17"
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
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-17",
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-17/*"
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
