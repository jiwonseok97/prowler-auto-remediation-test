resource "aws_s3_bucket_policy" "fix_s3_secure_transport_1c80b6cecd" {
  bucket = "vuln-demo-ap-northeast-2-20-ec247f50"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-ec247f50",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-ec247f50/*"
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
