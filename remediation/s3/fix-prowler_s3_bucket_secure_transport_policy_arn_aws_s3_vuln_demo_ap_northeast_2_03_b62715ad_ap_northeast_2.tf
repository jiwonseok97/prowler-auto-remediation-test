resource "aws_s3_bucket_policy" "fix_s3_secure_transport_fc90911c64" {
  bucket = "vuln-demo-ap-northeast-2-03-b62715ad"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-b62715ad",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-b62715ad/*"
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
