resource "aws_s3_bucket_policy" "fix_s3_secure_transport_33e2f9f47b" {
  bucket = "vuln-demo-ap-northeast-2-12-424f7b39"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-424f7b39",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-424f7b39/*"
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
