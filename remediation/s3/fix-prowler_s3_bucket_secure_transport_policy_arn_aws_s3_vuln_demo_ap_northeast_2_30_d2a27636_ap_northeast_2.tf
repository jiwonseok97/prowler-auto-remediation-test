resource "aws_s3_bucket_policy" "fix_s3_secure_transport_f1c4919ec2" {
  bucket = "vuln-demo-ap-northeast-2-30-d2a27636"
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
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-d2a27636",
        "arn:aws:s3:::vuln-demo-ap-northeast-2-30-d2a27636/*"
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
