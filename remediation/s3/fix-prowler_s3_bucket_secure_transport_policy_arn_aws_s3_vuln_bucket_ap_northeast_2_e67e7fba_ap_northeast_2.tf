resource "aws_s3_bucket_policy" "fix_s3_secure_transport_b794119485" {
  bucket = "vuln-bucket-ap-northeast-2-e67e7fba"
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
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-e67e7fba",
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-e67e7fba/*"
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
