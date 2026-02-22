resource "aws_s3_bucket_policy" "fix_s3_secure_transport_3af4045a4e" {
  bucket = "vuln-demo-ap-northeast-2-08-d4e32636"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-d4e32636",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-d4e32636/*"
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
