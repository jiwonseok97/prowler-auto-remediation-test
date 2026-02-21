resource "aws_s3_bucket_policy" "fix_s3_secure_transport_38a46d603b" {
  bucket = "vuln-demo-ap-northeast-2-26-76143ea2"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-26-76143ea2",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-26-76143ea2/*"
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
