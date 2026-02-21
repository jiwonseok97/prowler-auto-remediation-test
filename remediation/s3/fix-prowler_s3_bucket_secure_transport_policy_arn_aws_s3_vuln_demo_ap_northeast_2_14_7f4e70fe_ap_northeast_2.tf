resource "aws_s3_bucket_policy" "fix_s3_secure_transport_95ddfc9b9e" {
  bucket = "vuln-demo-ap-northeast-2-14-7f4e70fe"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-7f4e70fe",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-14-7f4e70fe/*"
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
