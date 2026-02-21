resource "aws_s3_bucket_policy" "fix_s3_secure_transport_cd90a0830f" {
  bucket = "vuln-demo-ap-northeast-2-04-0e2d8f97"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-0e2d8f97",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-0e2d8f97/*"
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
