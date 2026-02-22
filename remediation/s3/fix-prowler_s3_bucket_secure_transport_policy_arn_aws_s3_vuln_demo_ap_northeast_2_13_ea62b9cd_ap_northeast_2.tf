resource "aws_s3_bucket_policy" "fix_s3_secure_transport_a9a0cc7705" {
  bucket = "vuln-demo-ap-northeast-2-13-ea62b9cd"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-ea62b9cd",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-ea62b9cd/*"
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
