resource "aws_s3_bucket_policy" "fix_s3_secure_transport_518c701d56" {
  bucket = "vuln-demo-ap-northeast-2-03-6db9b717"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-6db9b717",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-6db9b717/*"
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
