resource "aws_s3_bucket_policy" "fix_s3_secure_transport_9214f131c2" {
  bucket = "vuln-demo-ap-northeast-2-06-ffa9fb14"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-ffa9fb14",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-06-ffa9fb14/*"
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
