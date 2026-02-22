resource "aws_s3_bucket_policy" "fix_s3_secure_transport_1eb4c20a00" {
  bucket = "vuln-demo-ap-northeast-2-09-2a22e10c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-2a22e10c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-2a22e10c/*"
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
