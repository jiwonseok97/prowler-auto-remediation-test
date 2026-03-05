resource "aws_s3_bucket_policy" "fix_s3_secure_transport_bd4a0744e1" {
  bucket = "vuln-demo-ap-northeast-2-09-a86c2d63"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-a86c2d63",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-09-a86c2d63/*"
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
