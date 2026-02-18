variable "aws_region" {
  type        = string
  description = "AWS region for vulnerable test infra"
}

variable "multi_region" {
  type        = bool
  description = "Whether to create multi-region CloudTrail"
  default     = true
}
