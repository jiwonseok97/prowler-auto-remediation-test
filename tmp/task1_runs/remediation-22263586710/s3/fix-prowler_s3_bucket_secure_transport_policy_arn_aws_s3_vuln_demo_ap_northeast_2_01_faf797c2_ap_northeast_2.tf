resource "aws_s3_bucket_policy" "fix_s3_secure_transport_3058a5fcc2" {
  bucket = "vuln-demo-ap-northeast-2-01-faf797c2"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-faf797c2",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-01-faf797c2/*"
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
