resource "aws_s3_bucket_policy" "fix_s3_secure_transport_b2453d0746" {
  bucket = "vuln-demo-ap-northeast-2-06-618eb5f1"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-618eb5f1",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-618eb5f1/*"
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
