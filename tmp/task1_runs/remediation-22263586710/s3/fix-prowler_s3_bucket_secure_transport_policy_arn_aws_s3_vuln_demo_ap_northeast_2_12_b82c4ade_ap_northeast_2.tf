resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bf2828caf5" {
  bucket = "vuln-demo-ap-northeast-2-12-b82c4ade"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-b82c4ade",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-b82c4ade/*"
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
