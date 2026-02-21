resource "aws_s3_bucket_policy" "fix_s3_secure_transport_c4cc98d85b" {
  bucket = "vuln-demo-ap-northeast-2-34-782f05cc"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-782f05cc",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-782f05cc/*"
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
