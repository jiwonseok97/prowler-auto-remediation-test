resource "aws_kms_key" "fix_kms_rotation_ba3b84e475" {
  enable_key_rotation = true
  policy              = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Sid\": \"EnableRootAndCallerPermissions\", \"Effect\": \"Allow\", \"Principal\": {\"AWS\": [\"arn:aws:iam::132410971304:root\", \"arn:aws:iam::132410971304:role/GitHubActionsProwlerRole\"]}, \"Action\": \"kms:*\", \"Resource\": \"*\"}]}"
}
