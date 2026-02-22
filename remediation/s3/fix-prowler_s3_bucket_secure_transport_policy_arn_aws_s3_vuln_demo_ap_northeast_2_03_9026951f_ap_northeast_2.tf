resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e94a42f43f" {
  bucket = "vuln-demo-ap-northeast-2-03-9026951f"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-9026951f",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-9026951f/*"
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
