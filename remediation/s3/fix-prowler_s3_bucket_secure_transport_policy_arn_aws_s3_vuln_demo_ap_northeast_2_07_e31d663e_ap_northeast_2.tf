resource "aws_s3_bucket_policy" "fix_s3_secure_transport_1f68e8fabc" {
  bucket = "vuln-demo-ap-northeast-2-07-e31d663e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-e31d663e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-e31d663e/*"
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
