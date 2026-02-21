output "account_id" {
  value = var.account_id
}

output "region" {
  value = var.region
}

output "vulnerable_buckets" {
  value = aws_s3_bucket.vuln_bucket[*].bucket
}

output "vulnerable_security_groups" {
  value = aws_security_group.vuln_sg[*].id
}

output "cloudtrail_name" {
  value = aws_cloudtrail.vuln_trail.name
}

output "vulnerable_iam_users" {
  value = aws_iam_user.vuln_user[*].name
}

output "vuln_log_groups" {
  value = aws_cloudwatch_log_group.vuln_logs[*].name
}
