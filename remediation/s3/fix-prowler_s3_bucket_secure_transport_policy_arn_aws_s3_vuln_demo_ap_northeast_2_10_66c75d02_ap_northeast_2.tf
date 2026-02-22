resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0ddda77ea5" {
  bucket = "vuln-demo-ap-northeast-2-10-66c75d02"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-66c75d02",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-66c75d02/*"
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
