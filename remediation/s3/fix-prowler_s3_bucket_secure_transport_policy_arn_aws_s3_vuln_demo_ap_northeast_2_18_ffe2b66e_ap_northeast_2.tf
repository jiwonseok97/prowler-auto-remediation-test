resource "aws_s3_bucket_policy" "fix_s3_secure_transport_1dfa88b774" {
  bucket = "vuln-demo-ap-northeast-2-18-ffe2b66e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-ffe2b66e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-ffe2b66e/*"
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
