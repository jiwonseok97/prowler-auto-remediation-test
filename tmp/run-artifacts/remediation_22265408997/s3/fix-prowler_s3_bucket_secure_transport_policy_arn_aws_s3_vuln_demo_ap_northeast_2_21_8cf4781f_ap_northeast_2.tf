resource "aws_s3_bucket_policy" "fix_s3_secure_transport_8647f56944" {
  bucket = "vuln-demo-ap-northeast-2-21-8cf4781f"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-21-8cf4781f",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-21-8cf4781f/*"
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
