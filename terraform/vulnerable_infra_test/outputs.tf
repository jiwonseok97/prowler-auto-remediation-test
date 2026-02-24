output "account_id" {
  value = var.account_id
}

output "region" {
  value = var.region
}

output "vulnerable_buckets" {
  value = aws_s3_bucket.vuln_bucket[*].bucket
}

output "vuln_log_groups" {
  value = aws_cloudwatch_log_group.vuln_logs[*].name
}

output "vuln_trail_name" {
  value = var.create_vuln_cloudtrail ? aws_cloudtrail.vuln_trail[0].name : null
}

output "vuln_trail_bucket" {
  value = var.create_vuln_cloudtrail ? aws_s3_bucket.vuln_trail_logs[0].bucket : null
}

output "default_sg_id" {
  value = var.open_default_security_group ? aws_default_security_group.vuln_default_sg[0].id : null
}

output "vuln_kms_key_ids" {
  value = aws_kms_key.vuln_kms[*].key_id
}

output "ebs_default_encryption_enabled" {
  value = aws_ebs_encryption_by_default.vuln_ebs_enc.enabled
}
