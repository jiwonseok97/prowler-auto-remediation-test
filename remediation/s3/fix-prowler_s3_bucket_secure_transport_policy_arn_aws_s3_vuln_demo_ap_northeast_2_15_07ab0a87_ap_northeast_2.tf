resource "aws_s3_bucket_policy" "fix_s3_secure_transport_eabc68d92a" {
  bucket = "vuln-demo-ap-northeast-2-15-07ab0a87"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-15-07ab0a87",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-15-07ab0a87/*"
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
