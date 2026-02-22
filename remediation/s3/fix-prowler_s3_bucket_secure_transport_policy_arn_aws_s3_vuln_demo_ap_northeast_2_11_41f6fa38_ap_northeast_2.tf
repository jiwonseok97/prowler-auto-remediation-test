resource "aws_s3_bucket_policy" "fix_s3_secure_transport_afc3c8ac2d" {
  bucket = "vuln-demo-ap-northeast-2-11-41f6fa38"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-41f6fa38",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-41f6fa38/*"
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
