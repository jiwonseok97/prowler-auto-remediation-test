resource "aws_s3_bucket_policy" "fix_s3_secure_transport_9509dc40ad" {
  bucket = "vuln-bucket-ap-northeast-2-9c753e89"
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
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-9c753e89",
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-9c753e89/*"
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
