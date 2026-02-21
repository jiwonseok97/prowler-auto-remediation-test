resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bbffa64b5e" {
  bucket = "vuln-demo-ap-northeast-2-06-b3c30f9e"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-b3c30f9e",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-b3c30f9e/*"
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
