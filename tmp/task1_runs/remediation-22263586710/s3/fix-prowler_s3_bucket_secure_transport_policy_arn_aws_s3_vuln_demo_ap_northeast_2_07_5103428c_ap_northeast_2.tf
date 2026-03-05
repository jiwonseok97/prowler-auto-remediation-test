resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0f582a50c4" {
  bucket = "vuln-demo-ap-northeast-2-07-5103428c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-5103428c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-5103428c/*"
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
