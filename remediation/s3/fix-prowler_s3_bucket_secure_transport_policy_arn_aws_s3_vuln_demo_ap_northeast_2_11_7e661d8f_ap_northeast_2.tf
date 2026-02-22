resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d5261fd21d" {
  bucket = "vuln-demo-ap-northeast-2-11-7e661d8f"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-7e661d8f",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-7e661d8f/*"
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
