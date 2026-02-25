resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0b33e2007e" {
  bucket = "vuln-demo-132410971304-ap-northeast-2-11"
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
        "arn:aws:s3:::vuln-demo-132410971304-ap-northeast-2-11",
        "arn:aws:s3:::vuln-demo-132410971304-ap-northeast-2-11/*"
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
