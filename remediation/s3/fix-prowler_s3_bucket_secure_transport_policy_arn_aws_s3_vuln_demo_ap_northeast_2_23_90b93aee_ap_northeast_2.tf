resource "aws_s3_bucket_policy" "fix_s3_secure_transport_24710b0268" {
  bucket = "vuln-demo-ap-northeast-2-23-90b93aee"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-23-90b93aee",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-23-90b93aee/*"
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
