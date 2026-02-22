resource "aws_s3_bucket_policy" "fix_s3_secure_transport_54cf1d9a3e" {
  bucket = "vuln-demo-ap-northeast-2-04-83d2a800"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-83d2a800",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-83d2a800/*"
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
