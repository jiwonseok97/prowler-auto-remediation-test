resource "aws_s3_bucket_policy" "fix_s3_secure_transport_2a318ba449" {
  bucket = "vuln-demo-ap-northeast-2-01-4c5687d9"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-4c5687d9",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-4c5687d9/*"
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
