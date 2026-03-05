resource "aws_s3_bucket_policy" "fix_s3_secure_transport_9081c3815d" {
  bucket = "vuln-demo-ap-northeast-2-30-416d8842"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-416d8842",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-416d8842/*"
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
