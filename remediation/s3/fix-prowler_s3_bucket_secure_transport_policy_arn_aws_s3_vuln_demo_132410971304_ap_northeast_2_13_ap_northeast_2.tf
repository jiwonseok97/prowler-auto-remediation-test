resource "aws_s3_bucket_policy" "fix_s3_secure_transport_6dd60b5c7a" {
  bucket = "vuln-demo-132410971304-ap-northeast-2-13"
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
        "arn:aws:s3:::vuln-demo-132410971304-ap-northeast-2-13",
        "arn:aws:s3:::vuln-demo-132410971304-ap-northeast-2-13/*"
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
