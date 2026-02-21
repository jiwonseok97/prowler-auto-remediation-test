resource "aws_s3_bucket_policy" "fix_s3_secure_transport_eb4eb1c49f" {
  bucket = "vuln-demo-ap-northeast-2-05-b2236696"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-b2236696",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-05-b2236696/*"
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
