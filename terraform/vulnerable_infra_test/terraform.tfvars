account_id = "123456789012"
region     = "ap-northeast-2"

# S3: PAB false + 암호화 없음 → ~21건 FAIL (10×2 + 1 account)
vuln_bucket_count = 10

# CloudWatch: KMS 없음 → 5건 FAIL
cloudwatch_log_group_count = 5

# IAM: 약한 패스워드 정책 → 6건 FAIL
create_weak_account_password_policy = true

# CloudTrail: 검증/KMS/CW로깅/데이터이벤트 미설정 → 3~5건 FAIL
create_vuln_cloudtrail = true

# EC2/VPC: Default SG 전체 허용 → 1건 FAIL (auto-remediable)
open_default_security_group = true

# EC2: EBS 기본 암호화 비활성화 → 1건 FAIL (auto-remediable)
# (aws_ebs_encryption_by_default.vuln_ebs_enc)

# S3: 버킷 버저닝 미설정 → 10건 FAIL (auto-remediable)
# (aws_s3_bucket_versioning 각 버킷)

# KMS: CMK 자동 교체 비활성화 → 2건 FAIL (auto-remediable, IMPORT_AND_PATCH)
vuln_kms_key_count = 2
