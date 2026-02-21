resource "aws_s3_bucket_policy" "fix_s3_secure_transport_3bf13ae9ac" {
  bucket = "vuln-demo-ap-northeast-2-01-e1b943eb"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-e1b943eb",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-e1b943eb/*"
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
