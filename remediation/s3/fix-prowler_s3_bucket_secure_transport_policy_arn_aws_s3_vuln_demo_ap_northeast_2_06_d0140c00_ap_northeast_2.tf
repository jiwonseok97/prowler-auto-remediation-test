resource "aws_s3_bucket_policy" "fix_s3_secure_transport_34ffa966a0" {
  bucket = "vuln-demo-ap-northeast-2-06-d0140c00"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-d0140c00",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-d0140c00/*"
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
