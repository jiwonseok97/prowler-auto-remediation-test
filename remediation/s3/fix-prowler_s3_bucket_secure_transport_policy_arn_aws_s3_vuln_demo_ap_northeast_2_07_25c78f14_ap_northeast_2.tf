resource "aws_s3_bucket_policy" "fix_s3_secure_transport_8e0464254b" {
  bucket = "vuln-demo-ap-northeast-2-07-25c78f14"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-25c78f14",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-25c78f14/*"
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
