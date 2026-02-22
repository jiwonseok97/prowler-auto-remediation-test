resource "aws_s3_bucket_policy" "fix_s3_secure_transport_db7c3512f8" {
  bucket = "vuln-demo-ap-northeast-2-02-282b3f01"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-282b3f01",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-282b3f01/*"
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
