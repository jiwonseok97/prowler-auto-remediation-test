resource "aws_s3_bucket_policy" "fix_s3_secure_transport_d3e55f9d03" {
  bucket = "vuln-demo-ap-northeast-2-26-692d7484"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-26-692d7484",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-26-692d7484/*"
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
