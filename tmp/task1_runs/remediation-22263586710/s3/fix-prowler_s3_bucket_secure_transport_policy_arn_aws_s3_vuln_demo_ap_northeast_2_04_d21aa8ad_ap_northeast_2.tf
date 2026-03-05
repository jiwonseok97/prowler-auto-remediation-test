resource "aws_s3_bucket_policy" "fix_s3_secure_transport_dead0ff061" {
  bucket = "vuln-demo-ap-northeast-2-04-d21aa8ad"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-d21aa8ad",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-d21aa8ad/*"
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
