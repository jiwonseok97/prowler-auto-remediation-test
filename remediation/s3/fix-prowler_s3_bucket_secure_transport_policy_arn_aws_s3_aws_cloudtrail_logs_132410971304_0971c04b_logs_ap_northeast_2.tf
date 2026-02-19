resource "aws_s3_bucket_policy" "fix_s3_secure_transport_26b0cb1663" {
  bucket = "aws-cloudtrail-logs-132410971304-0971c04b-logs"
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
        "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b-logs",
        "arn:aws:s3:::aws-cloudtrail-logs-132410971304-0971c04b-logs/*"
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
