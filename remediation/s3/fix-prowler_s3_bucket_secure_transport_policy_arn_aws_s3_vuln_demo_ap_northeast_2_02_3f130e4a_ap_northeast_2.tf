resource "aws_s3_bucket_policy" "fix_s3_secure_transport_507fbf99f9" {
  bucket = "vuln-demo-ap-northeast-2-02-3f130e4a"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-3f130e4a",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-02-3f130e4a/*"
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
