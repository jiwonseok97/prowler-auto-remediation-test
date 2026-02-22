resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bf28ef0f82" {
  bucket = "vuln-demo-ap-northeast-2-34-acd00f04"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-acd00f04",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-34-acd00f04/*"
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
