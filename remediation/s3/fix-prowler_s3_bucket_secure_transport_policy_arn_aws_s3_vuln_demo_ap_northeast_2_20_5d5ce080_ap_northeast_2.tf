resource "aws_s3_bucket_policy" "fix_s3_secure_transport_681f8025ca" {
  bucket = "vuln-demo-ap-northeast-2-20-5d5ce080"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-5d5ce080",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-5d5ce080/*"
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
