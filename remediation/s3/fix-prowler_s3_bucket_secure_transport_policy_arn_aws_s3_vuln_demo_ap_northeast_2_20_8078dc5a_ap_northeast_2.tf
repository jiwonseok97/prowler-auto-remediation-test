resource "aws_s3_bucket_policy" "fix_s3_secure_transport_75a7d3bf06" {
  bucket = "vuln-demo-ap-northeast-2-20-8078dc5a"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-8078dc5a",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-20-8078dc5a/*"
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
