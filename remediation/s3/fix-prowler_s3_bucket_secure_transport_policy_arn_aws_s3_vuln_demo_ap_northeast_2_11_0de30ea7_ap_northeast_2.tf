resource "aws_s3_bucket_policy" "fix_s3_secure_transport_95005f4778" {
  bucket = "vuln-demo-ap-northeast-2-11-0de30ea7"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-0de30ea7",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-11-0de30ea7/*"
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
