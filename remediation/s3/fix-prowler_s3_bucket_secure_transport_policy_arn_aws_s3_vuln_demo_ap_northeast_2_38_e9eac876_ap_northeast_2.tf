resource "aws_s3_bucket_policy" "fix_s3_secure_transport_16915983a0" {
  bucket = "vuln-demo-ap-northeast-2-38-e9eac876"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-38-e9eac876",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-38-e9eac876/*"
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
