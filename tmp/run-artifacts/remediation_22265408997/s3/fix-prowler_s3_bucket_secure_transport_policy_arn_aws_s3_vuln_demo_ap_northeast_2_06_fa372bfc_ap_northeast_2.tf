resource "aws_s3_bucket_policy" "fix_s3_secure_transport_2c212421b0" {
  bucket = "vuln-demo-ap-northeast-2-06-fa372bfc"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-fa372bfc",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-fa372bfc/*"
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
