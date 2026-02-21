resource "aws_s3_bucket_policy" "fix_s3_secure_transport_36dbc4473b" {
  bucket = "vuln-demo-ap-northeast-2-34-00f50540"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-00f50540",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-00f50540/*"
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
