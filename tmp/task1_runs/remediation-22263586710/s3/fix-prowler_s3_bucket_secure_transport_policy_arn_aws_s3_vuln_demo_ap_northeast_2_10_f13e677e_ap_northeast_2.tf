resource "aws_s3_bucket_policy" "fix_s3_secure_transport_221a6e4380" {
  bucket = "vuln-demo-ap-northeast-2-10-f13e677e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-f13e677e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-f13e677e/*"
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
