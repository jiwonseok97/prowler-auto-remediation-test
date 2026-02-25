resource "aws_s3_bucket_policy" "fix_s3_secure_transport_68f79c5437" {
  bucket = "vuln-cloudtrail-132410971304-ap-northeast-2"
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
        "arn:aws:s3:::vuln-cloudtrail-132410971304-ap-northeast-2",
        "arn:aws:s3:::vuln-cloudtrail-132410971304-ap-northeast-2/*"
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
