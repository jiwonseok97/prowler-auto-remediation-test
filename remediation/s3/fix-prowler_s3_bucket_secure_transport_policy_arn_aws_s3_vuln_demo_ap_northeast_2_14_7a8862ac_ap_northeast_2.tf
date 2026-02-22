resource "aws_s3_bucket_policy" "fix_s3_secure_transport_878da56c73" {
  bucket = "vuln-demo-ap-northeast-2-14-7a8862ac"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-7a8862ac",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-7a8862ac/*"
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
