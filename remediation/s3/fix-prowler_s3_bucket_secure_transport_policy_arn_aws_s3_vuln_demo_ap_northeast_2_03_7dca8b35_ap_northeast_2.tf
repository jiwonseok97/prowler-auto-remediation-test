resource "aws_s3_bucket_policy" "fix_s3_secure_transport_3bfe85838d" {
  bucket = "vuln-demo-ap-northeast-2-03-7dca8b35"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-7dca8b35",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-7dca8b35/*"
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
