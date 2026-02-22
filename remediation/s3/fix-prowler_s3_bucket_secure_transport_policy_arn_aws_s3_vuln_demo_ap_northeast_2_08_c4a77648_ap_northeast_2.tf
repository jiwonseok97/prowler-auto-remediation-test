resource "aws_s3_bucket_policy" "fix_s3_secure_transport_770c7d3dec" {
  bucket = "vuln-demo-ap-northeast-2-08-c4a77648"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-c4a77648",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-c4a77648/*"
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
