resource "aws_s3_bucket_policy" "fix_s3_secure_transport_cc4b6646ec" {
  bucket = "vuln-demo-ap-northeast-2-37-5faa0ae0"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-37-5faa0ae0",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-37-5faa0ae0/*"
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
