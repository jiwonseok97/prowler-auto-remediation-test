resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e231c09b4a" {
  bucket = "vuln-demo-ap-northeast-2-11-19544e4c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-19544e4c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-19544e4c/*"
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
