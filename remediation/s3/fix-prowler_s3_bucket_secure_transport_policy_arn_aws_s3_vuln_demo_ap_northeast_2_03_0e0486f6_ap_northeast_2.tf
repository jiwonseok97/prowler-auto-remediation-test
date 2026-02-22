resource "aws_s3_bucket_policy" "fix_s3_secure_transport_92a002e188" {
  bucket = "vuln-demo-ap-northeast-2-03-0e0486f6"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-0e0486f6",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-0e0486f6/*"
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
