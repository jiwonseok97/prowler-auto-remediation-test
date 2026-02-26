variable "account_id" {
  type        = string
  description = "AWS account ID"
}

variable "region" {
  type        = string
  description = "Primary region for vulnerable test infra"
}

variable "mode" {
  type        = string
  description = "Deployment mode: vuln or remediate"
  default     = "vuln"
  validation {
    condition     = contains(["vuln", "remediate"], var.mode)
    error_message = "mode must be one of: vuln, remediate."
  }
}

variable "vuln_bucket_count" {
  type        = number
  description = "S3 버킷 수 (PAB false + 암호화 없음 → s3 FAIL ×2N + 1)"
  default     = 10
}

variable "cloudwatch_log_group_count" {
  type        = number
  description = "CloudWatch 로그 그룹 수 (KMS 없음 → cloudwatch_log_group_encrypted FAIL ×N)"
  default     = 5
}

variable "create_weak_account_password_policy" {
  type        = bool
  description = "약한 IAM 패스워드 정책 생성 → 6종 IAM FAIL"
  default     = true
}

variable "create_vuln_cloudtrail" {
  type        = bool
  description = "취약 CloudTrail 생성 (검증/KMS/CW로깅/데이터이벤트 미설정) → 3~5종 CloudTrail FAIL"
  default     = true
}

variable "open_default_security_group" {
  type        = bool
  description = "Default SG 전체 허용 설정 → ec2_securitygroup_default_restrict_traffic FAIL (auto-remediable)"
  default     = true
}

variable "vuln_kms_key_count" {
  type        = number
  description = "KMS CMK 자동 교체 비활성화 키 수 → kms_cmk_rotation_enabled FAIL ×N (auto-remediable)"
  default     = 2
}

variable "vuln_vpc_count" {
  type        = number
  description = "flow logs 없는 VPC 수 → vpc_flow_logs_enabled + ec2_securitygroup_default_restrict_traffic FAIL ×N"
  default     = 2
}

variable "create_vuln_iam_direct_policy_user" {
  type        = bool
  description = "IAM 사용자에게 정책 직접 부여 (그룹/Role 우회) → iam_policy_attached_only_to_group_or_roles FAIL ×1 (review-then-apply)"
  default     = true
}

variable "create_vuln_ebs_disabled" {
  type        = bool
  description = "EBS 기본 암호화 비활성화 → ec2_ebs_default_encryption_enabled FAIL ×1 (ec2:DisableEbsEncryptionByDefault 권한 필요)"
  default     = false
}

variable "rds_instance_count" {
  type        = number
  description = "RDS ???? ? (vuln/remediate ??)"
  default     = 1
}

variable "efs_count" {
  type        = number
  description = "EFS ????? ? (vuln/remediate ??)"
  default     = 1
}

variable "alb_count" {
  type        = number
  description = "?? ALB ? (vuln/remediate ??)"
  default     = 1
}

variable "sns_topic_count" {
  type        = number
  description = "SNS ?? ? (vuln/remediate ??)"
  default     = 3
}

variable "sqs_queue_count" {
  type        = number
  description = "SQS ? ? (vuln/remediate ??)"
  default     = 3
}

