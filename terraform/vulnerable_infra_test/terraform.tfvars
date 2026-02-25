account_id = "123456789012"
region     = "ap-northeast-2"

# S3: PAB false + 암호화 없음 + SecureTransport 없음
#   → s3_bucket_level_public_access_block  ×15 FAIL
#   → s3_bucket_default_encryption          ×15 FAIL
#   → s3_bucket_secure_transport_policy     ×15 FAIL (pipeline 자동 fix)
#   → s3_account_level_public_access_blocks  ×1 FAIL
#   → s3_bucket_versioning_enabled          ×15 FAIL (isms_p 추가)
#   계 = 61건 FAIL
vuln_bucket_count = 15

# CloudWatch: KMS 없음
#   → cloudwatch_log_group_encrypted ×20 FAIL (isms_p 추가)
cloudwatch_log_group_count = 20

# IAM: 약한 패스워드 정책 → 5건 FAIL
create_weak_account_password_policy = true

# CloudTrail: 검증/KMS/CW로깅/데이터이벤트/S3접근로깅 미설정 → 5건 FAIL
create_vuln_cloudtrail = true

# IAM: 정책 직접 부여 (그룹/Role 우회) → 1건 FAIL (review-then-apply)
# GitHubActionsProwlerRole에 iam:CreateUser/CreatePolicy 권한 필요 → 현재 비활성화
create_vuln_iam_direct_policy_user = false

# EBS: 기본 암호화 비활성화 → ec2:DisableEbsEncryptionByDefault 권한 필요 → 현재 비활성화
create_vuln_ebs_disabled = false

# EC2/VPC: Default SG 전체 허용 → 1건 FAIL (auto-remediable)
open_default_security_group = true

# KMS: CMK 자동 교체 비활성화 → 3건 FAIL (auto-remediable, IMPORT_AND_PATCH)
vuln_kms_key_count = 3

# VPC: flow logs 없음 + default SG 허용
#   → vpc_flow_logs_enabled               ×2 FAIL (auto-remediable)
#   → ec2_securitygroup_default_restrict_traffic ×2 FAIL (auto-remediable)
vuln_vpc_count = 2
