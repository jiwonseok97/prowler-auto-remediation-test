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
  description = "Number of intentionally vulnerable S3 buckets (kept low to avoid manual-runbook-only noise)"
  default     = 0
}

variable "security_group_count" {
  type        = number
  description = "Number of wide-open security groups (kept low unless SG-focused demo is needed)"
  default     = 0
}

variable "cloudwatch_log_group_count" {
  type        = number
  description = "Number of intentionally unencrypted CloudWatch log groups (auto-remediation-friendly)"
  default     = 60
}
