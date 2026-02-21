resource "aws_s3_bucket_policy" "fix_s3_secure_transport_9d0d356b71" {
  bucket = "vuln-demo-ap-northeast-2-40-4688bce7"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-4688bce7",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-40-4688bce7/*"
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
