resource "aws_s3_bucket_policy" "fix_s3_secure_transport_5f35454dfb" {
  bucket = "vuln-demo-ap-northeast-2-35-4b132a46"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-35-4b132a46",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-35-4b132a46/*"
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
