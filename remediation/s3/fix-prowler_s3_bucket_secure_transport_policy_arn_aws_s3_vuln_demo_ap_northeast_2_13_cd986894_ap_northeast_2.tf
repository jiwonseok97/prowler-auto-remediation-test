resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e778a9ee1e" {
  bucket = "vuln-demo-ap-northeast-2-13-cd986894"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-cd986894",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-cd986894/*"
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
