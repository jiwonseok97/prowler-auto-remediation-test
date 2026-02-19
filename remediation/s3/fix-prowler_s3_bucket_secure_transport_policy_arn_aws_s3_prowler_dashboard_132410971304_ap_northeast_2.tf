resource "aws_s3_bucket_policy" "fix_s3_secure_transport_02a8c829a9" {
  bucket = "prowler-dashboard-132410971304"
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
        "arn:aws:s3:::prowler-dashboard-132410971304",
        "arn:aws:s3:::prowler-dashboard-132410971304/*"
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
