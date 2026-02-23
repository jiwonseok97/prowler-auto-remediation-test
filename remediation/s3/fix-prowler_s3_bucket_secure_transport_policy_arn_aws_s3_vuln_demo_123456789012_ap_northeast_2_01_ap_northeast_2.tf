resource "aws_s3_bucket_policy" "fix_s3_secure_transport_47cad284c0" {
  bucket = "vuln-demo-123456789012-ap-northeast-2-01"
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
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-01",
        "arn:aws:s3:::vuln-demo-123456789012-ap-northeast-2-01/*"
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
