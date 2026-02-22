resource "aws_s3_bucket_policy" "fix_s3_secure_transport_73881fb12c" {
  bucket = "vuln-demo-ap-northeast-2-29-3179b316"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-29-3179b316",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-29-3179b316/*"
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
