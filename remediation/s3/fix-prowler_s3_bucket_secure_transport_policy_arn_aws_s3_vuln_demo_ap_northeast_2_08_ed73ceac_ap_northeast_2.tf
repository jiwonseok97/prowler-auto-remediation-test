resource "aws_s3_bucket_policy" "fix_s3_secure_transport_a360473f89" {
  bucket = "vuln-demo-ap-northeast-2-08-ed73ceac"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-ed73ceac",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-08-ed73ceac/*"
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
