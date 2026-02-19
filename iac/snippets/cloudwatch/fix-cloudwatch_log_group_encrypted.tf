variable "log_group_name" {
  type = string
}

variable "kms_key_arn" {
  type = string
}

resource "aws_cloudwatch_log_group" "fix_cloudwatch_logs_kms" {
  name       = var.log_group_name
  kms_key_id = var.kms_key_arn

  lifecycle {
    ignore_changes = [retention_in_days, tags, tags_all]
  }
}
