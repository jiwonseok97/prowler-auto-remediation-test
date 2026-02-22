resource "aws_s3_bucket_policy" "fix_s3_secure_transport_169721c8ad" {
  bucket = "vuln-demo-ap-northeast-2-07-31ebc369"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-31ebc369",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-07-31ebc369/*"
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
