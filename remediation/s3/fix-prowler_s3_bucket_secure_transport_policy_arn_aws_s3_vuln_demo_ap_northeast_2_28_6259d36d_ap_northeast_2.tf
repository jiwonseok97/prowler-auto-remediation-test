resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bc207edb77" {
  bucket = "vuln-demo-ap-northeast-2-28-6259d36d"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-28-6259d36d",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-28-6259d36d/*"
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
