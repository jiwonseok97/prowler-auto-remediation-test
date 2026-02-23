resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d8b1c11942" {
  bucket = "vuln-demo-123456789012-ap-northeast-2-10"
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
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-10",
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-10/*"
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
