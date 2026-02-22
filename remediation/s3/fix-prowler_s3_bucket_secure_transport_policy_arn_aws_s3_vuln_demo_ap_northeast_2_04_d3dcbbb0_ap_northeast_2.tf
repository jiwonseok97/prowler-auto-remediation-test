resource "aws_s3_bucket_policy" "fix_s3_secure_transport_76e7629898" {
  bucket = "vuln-demo-ap-northeast-2-04-d3dcbbb0"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-d3dcbbb0",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-04-d3dcbbb0/*"
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
