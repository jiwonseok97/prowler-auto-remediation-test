variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "region" {
  type        = string
  description = "Primary region for vulnerable test infra"
}

variable "multi_region" {
  type        = bool
  description = "Whether CloudTrail is multi-region"
  default     = true
}

variable "vuln_bucket_count" {
  type        = number
  description = "Number of intentionally vulnerable S3 buckets"
  default     = 10
}

variable "iam_user_count" {
  type        = number
  description = "Number of vulnerable IAM users to create"
  default     = 6
}

variable "vpc_count" {
  type        = number
  description = "Number of vulnerable VPCs/security groups"
  default     = 4
}

variable "cloudwatch_log_group_count" {
  type        = number
  description = "Number of unencrypted CloudWatch log groups"
  default     = 4
}
