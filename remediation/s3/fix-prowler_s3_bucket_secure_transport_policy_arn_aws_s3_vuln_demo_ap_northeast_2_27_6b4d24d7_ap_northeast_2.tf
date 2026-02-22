resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d033a9c435" {
  bucket = "vuln-demo-ap-northeast-2-27-6b4d24d7"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-27-6b4d24d7",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-27-6b4d24d7/*"
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
