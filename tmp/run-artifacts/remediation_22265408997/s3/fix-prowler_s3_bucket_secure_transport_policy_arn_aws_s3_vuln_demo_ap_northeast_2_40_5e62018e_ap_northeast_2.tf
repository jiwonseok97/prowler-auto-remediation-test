resource "aws_s3_bucket_policy" "fix_s3_secure_transport_76bd896c80" {
  bucket = "vuln-demo-ap-northeast-2-40-5e62018e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-5e62018e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-5e62018e/*"
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
