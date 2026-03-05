resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ba4e922a0d" {
  bucket = "vuln-demo-ap-northeast-2-17-6f140204"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-6f140204",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-17-6f140204/*"
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
