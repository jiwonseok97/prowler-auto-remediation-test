resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e58b481f2c" {
  bucket = "vuln-demo-ap-northeast-2-18-8228833c"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-8228833c",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-18-8228833c/*"
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
