resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f0b344e6ea" {
  bucket = "vuln-demo-ap-northeast-2-16-2694b5a9"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-2694b5a9",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-2694b5a9/*"
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
