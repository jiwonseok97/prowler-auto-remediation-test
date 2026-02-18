variable "aws_region" {
  type        = string
  description = "AWS region for remediation apply"
}

variable "remediation_run_id" {
  type        = string
  default     = "manual"
}
