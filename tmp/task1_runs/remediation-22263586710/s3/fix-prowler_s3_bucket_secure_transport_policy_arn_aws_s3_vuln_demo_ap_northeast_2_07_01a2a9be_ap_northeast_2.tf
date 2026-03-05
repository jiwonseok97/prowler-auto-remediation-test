resource "aws_s3_bucket_policy" "fix_s3_secure_transport_8949a4b493" {
  bucket = "vuln-demo-ap-northeast-2-07-01a2a9be"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-01a2a9be",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-01a2a9be/*"
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
