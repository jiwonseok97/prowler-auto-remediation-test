# CloudWatch remediation snippet
resource "aws_cloudwatch_log_group" "secure_logs" {
  name              = "/secure/log-group"
  retention_in_days = 90
  kms_key_id        = "REPLACE_KMS_KEY_ARN"
}
