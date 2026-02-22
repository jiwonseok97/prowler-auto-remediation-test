resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c08d92c8e5" {
  bucket = "vuln-demo-ap-northeast-2-04-92bdcd7c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-92bdcd7c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-92bdcd7c/*"
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
