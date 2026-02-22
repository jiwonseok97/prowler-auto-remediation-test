resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0cb1e7a643" {
  bucket = "vuln-demo-ap-northeast-2-21-05bad01a"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-21-05bad01a",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-21-05bad01a/*"
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
