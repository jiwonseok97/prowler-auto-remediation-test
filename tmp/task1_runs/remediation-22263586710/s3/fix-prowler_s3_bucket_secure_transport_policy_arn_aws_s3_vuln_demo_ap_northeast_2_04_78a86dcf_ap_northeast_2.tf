resource "aws_s3_bucket_policy" "fix_s3_secure_transport_6008c9dfb3" {
  bucket = "vuln-demo-ap-northeast-2-04-78a86dcf"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-78a86dcf",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-78a86dcf/*"
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
