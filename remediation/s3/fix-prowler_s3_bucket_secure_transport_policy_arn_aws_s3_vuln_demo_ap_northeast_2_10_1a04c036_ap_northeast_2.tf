resource "aws_s3_bucket_policy" "fix_s3_secure_transport_61546884d0" {
  bucket = "vuln-demo-ap-northeast-2-10-1a04c036"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-1a04c036",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-1a04c036/*"
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
