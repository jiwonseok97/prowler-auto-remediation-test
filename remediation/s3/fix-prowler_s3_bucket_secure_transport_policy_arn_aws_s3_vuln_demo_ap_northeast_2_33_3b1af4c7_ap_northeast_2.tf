resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f2360e3a26" {
  bucket = "vuln-demo-ap-northeast-2-33-3b1af4c7"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-33-3b1af4c7",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-33-3b1af4c7/*"
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
