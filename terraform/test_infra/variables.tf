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
