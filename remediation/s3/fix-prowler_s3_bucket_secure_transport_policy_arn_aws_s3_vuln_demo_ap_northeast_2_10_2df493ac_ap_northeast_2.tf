resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c022553a96" {
  bucket = "vuln-demo-ap-northeast-2-10-2df493ac"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-2df493ac",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-2df493ac/*"
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
