resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d421a140bf" {
  bucket = "vuln-demo-ap-northeast-2-16-8f9b98ee"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-8f9b98ee",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-16-8f9b98ee/*"
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
