resource "aws_s3_bucket_policy" "fix_s3_secure_transport_e6194aac3b" {
  bucket = "vuln-cloudtrail-ap-northeast-2-f9fd7730"
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
        "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730",
        "arn:aws:s3:::vuln-cloudtrail-ap-northeast-2-f9fd7730/*"
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
