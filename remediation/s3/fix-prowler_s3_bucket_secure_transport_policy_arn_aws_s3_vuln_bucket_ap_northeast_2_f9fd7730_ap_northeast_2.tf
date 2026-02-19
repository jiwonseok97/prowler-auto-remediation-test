resource "aws_s3_bucket_policy" "fix_s3_secure_transport_09d6b6ce70" {
  bucket = "vuln-bucket-ap-northeast-2-f9fd7730"
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
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-f9fd7730",
        "arn:aws:s3:::vuln-bucket-ap-northeast-2-f9fd7730/*"
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
