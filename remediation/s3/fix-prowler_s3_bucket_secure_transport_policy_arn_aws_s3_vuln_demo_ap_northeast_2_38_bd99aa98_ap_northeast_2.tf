resource "aws_s3_bucket_policy" "fix_s3_secure_transport_62f71bac2f" {
  bucket = "vuln-demo-ap-northeast-2-38-bd99aa98"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-38-bd99aa98",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-38-bd99aa98/*"
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
