resource "aws_s3_bucket_policy" "fix_s3_secure_transport_a7ee717cad" {
  bucket = "vuln-demo-ap-northeast-2-12-55c28cb0"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-55c28cb0",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-12-55c28cb0/*"
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
