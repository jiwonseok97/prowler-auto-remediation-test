resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0cf1ec3458" {
  bucket = "vuln-demo-ap-northeast-2-14-ad077088"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-ad077088",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-ad077088/*"
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
