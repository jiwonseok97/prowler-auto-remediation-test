resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e636d5b3f7" {
  bucket = "vuln-demo-ap-northeast-2-35-fbf58d89"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-35-fbf58d89",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-35-fbf58d89/*"
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
