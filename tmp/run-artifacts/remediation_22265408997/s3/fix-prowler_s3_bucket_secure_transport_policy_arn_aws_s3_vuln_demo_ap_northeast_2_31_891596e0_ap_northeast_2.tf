resource "aws_s3_bucket_policy" "fix_s3_secure_transport_0a305d5d36" {
  bucket = "vuln-demo-ap-northeast-2-31-891596e0"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-31-891596e0",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-31-891596e0/*"
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
