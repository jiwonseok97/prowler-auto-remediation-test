resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bab706867a" {
  bucket = "vuln-demo-ap-northeast-2-20-2d0e07ee"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-2d0e07ee",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-2d0e07ee/*"
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
