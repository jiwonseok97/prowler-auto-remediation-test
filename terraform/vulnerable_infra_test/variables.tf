variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "region" {
  type        = string
  description = "Primary region for vulnerable test infra"
}

variable "vuln_bucket_count" {
  type        = number
  description = "Number of intentionally vulnerable S3 buckets (keep low/zero for auto-remediable demo mode)"
  default     = 0
}

variable "security_group_count" {
  type        = number
  description = "Number of wide-open security groups (auto-remediable demo driver)"
  default     = 36
}

variable "cloudwatch_log_group_count" {
  type        = number
  description = "Number of intentionally unencrypted CloudWatch log groups (optional; keep 0 unless mapped in your environment)"
  default     = 0
}

variable "create_weak_account_password_policy" {
  type        = bool
  description = "Create a weak IAM account password policy to trigger multiple auto-remediable IAM password policy checks"
  default     = true
}
