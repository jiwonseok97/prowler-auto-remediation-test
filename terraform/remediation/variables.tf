variable "region" {
  type        = string
  description = "AWS region for remediation apply"
}

variable "account_id" {
  type        = string
  description = "AWS account ID"
  default     = ""
}
