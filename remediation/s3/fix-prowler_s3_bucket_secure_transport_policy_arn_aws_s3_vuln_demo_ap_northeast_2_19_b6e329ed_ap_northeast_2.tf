resource "aws_s3_bucket_policy" "fix_s3_secure_transport_7456ff155c" {
  bucket = "vuln-demo-ap-northeast-2-19-b6e329ed"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-b6e329ed",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-19-b6e329ed/*"
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
