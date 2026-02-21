resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f5c55f0e6a" {
  bucket = "vuln-demo-ap-northeast-2-24-8dcfc588"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-24-8dcfc588",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-24-8dcfc588/*"
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
