resource "aws_s3_bucket_policy" "fix_s3_secure_transport_ae1a3130f2" {
  bucket = "vuln-demo-ap-northeast-2-01-35c2a988"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-35c2a988",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-35c2a988/*"
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
