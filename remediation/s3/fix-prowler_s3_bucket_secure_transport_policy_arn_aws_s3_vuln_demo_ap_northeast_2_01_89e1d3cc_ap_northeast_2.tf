resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ee00b66587" {
  bucket = "vuln-demo-ap-northeast-2-01-89e1d3cc"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-89e1d3cc",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-89e1d3cc/*"
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
