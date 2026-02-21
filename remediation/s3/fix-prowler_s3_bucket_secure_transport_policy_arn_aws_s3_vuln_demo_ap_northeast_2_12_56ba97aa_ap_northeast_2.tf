resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ec5a778e6c" {
  bucket = "vuln-demo-ap-northeast-2-12-56ba97aa"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-56ba97aa",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-56ba97aa/*"
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
