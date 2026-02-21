resource "aws_s3_bucket_policy" "fix_s3_secure_transport_a5f0c30cca" {
  bucket = "vuln-demo-ap-northeast-2-10-accc5799"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-accc5799",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-accc5799/*"
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
