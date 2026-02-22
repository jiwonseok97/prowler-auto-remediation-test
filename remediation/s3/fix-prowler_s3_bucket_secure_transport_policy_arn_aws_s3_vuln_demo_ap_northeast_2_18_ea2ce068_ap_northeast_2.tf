resource "aws_s3_bucket_policy" "fix_s3_secure_transport_fc8a4dda44" {
  bucket = "vuln-demo-ap-northeast-2-18-ea2ce068"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-ea2ce068",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-ea2ce068/*"
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
