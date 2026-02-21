resource "aws_s3_bucket_policy" "fix_s3_secure_transport_5893ec3d73" {
  bucket = "vuln-demo-ap-northeast-2-13-7777e99d"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-7777e99d",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-13-7777e99d/*"
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
