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
  description = "Number of intentionally vulnerable S3 buckets"
  default     = 20
}

variable "security_group_count" {
  type        = number
  description = "Number of wide-open security groups"
  default     = 12
}

variable "cloudwatch_log_group_count" {
  type        = number
  description = "Number of unencrypted CloudWatch log groups"
  default     = 8
}
