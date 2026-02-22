resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e8ce58b31f" {
  bucket = "vuln-demo-ap-northeast-2-10-774334bc"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-774334bc",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-10-774334bc/*"
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
