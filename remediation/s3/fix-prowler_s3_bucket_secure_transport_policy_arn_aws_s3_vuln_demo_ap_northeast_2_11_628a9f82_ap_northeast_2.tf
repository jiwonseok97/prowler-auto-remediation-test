resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ab7da581ad" {
  bucket = "vuln-demo-ap-northeast-2-11-628a9f82"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-628a9f82",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-628a9f82/*"
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
