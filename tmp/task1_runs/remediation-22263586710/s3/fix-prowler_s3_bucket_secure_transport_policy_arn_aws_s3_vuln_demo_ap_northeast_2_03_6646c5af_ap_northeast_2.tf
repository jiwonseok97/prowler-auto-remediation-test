resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f63c893aca" {
  bucket = "vuln-demo-ap-northeast-2-03-6646c5af"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-6646c5af",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-03-6646c5af/*"
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
