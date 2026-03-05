resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c320ba5c2f" {
  bucket = "vuln-demo-ap-northeast-2-19-bb152656"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-bb152656",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-bb152656/*"
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
