# Prowler Auto Remediation Test

AWS 취약 인프라를 의도적으로 배포하고, Prowler 3.11 스캔 결과를 기반으로 Bedrock(Claude 3 Haiku) + Builder가 Remediation Terraform을 생성하여 카테고리별 PR, Merge 후 Apply, 재스캔 FAIL 감소까지 시연하는 E2E PoC.

## 디렉토리
```text
prowler-auto-remediation-test/
├─ terraform/
│   ├─ test_infra/
│   │   ├─ backend.tf
│   │   ├─ main.tf
│   │   ├─ variables.tf
│   │   ├─ outputs.tf
│   │   └─ terraform.tfvars
│   └─ remediation/
│       ├─ main.tf
│       ├─ variables.tf
│       ├─ outputs.tf
│       ├─ manifest.json
│       └─ <category>/main.tf
├─ iac/
│   ├─ scripts/
│   │   ├─ convert_findings.py
│   │   ├─ generate_remediation.py
│   │   ├─ inject_lifecycle.py
│   │   ├─ resilient_apply.sh
│   │   ├─ auto_import.sh
│   │   └─ builder_to_manifest.py
│   ├─ builders/
│   │   ├─ cloudwatch_builder.py
│   │   └─ network_builder.py
│   ├─ snippets/
│   │   ├─ iam/
│   │   ├─ s3/
│   │   ├─ network-ec2-vpc/
│   │   ├─ cloudtrail/
│   │   └─ cloudwatch/
│   └─ check_to_iac.yaml
└─ .github/workflows/e2e-demo.yml
```

## 취약 환경 범위 (`terraform/test_infra`)
- IAM: 약한 계정 패스워드 정책, wildcard policy
- S3: public-read ACL, 암호화/로깅 미설정
- CloudTrail: log file validation 비활성, KMS 암호화 미사용
- CloudWatch: KMS 미설정 로그 그룹
- Network/VPC: all-open SG, VPC flow logs 미설정

## Workflow (`.github/workflows/e2e-demo.yml`)
- `deploy-vulnerable`: 취약 Terraform apply
- `scan`: Prowler 3.11(CIS 1.4) 스캔
- `generate-remediation`: findings 정규화 -> Bedrock/Builder 생성 -> manifest 생성
- `create-category-pr`: iam/s3/network-ec2-vpc/cloudtrail/cloudwatch 카테고리별 PR
- `wait-for-merge`: 수동 merge 또는 auto_merge=true 시 자동 merge 시도
- `cleanup`: 입력 cleanup=true 시 취약 인프라 destroy

## Merge 후 자동 적용 (`.github/workflows/apply-on-merge.yml`)
- 트리거: `main` push (remediation 파일 변경 시)
- `apply`: category별 auto import + resilient apply
- `verify`: 150초 대기 후 재스캔, baseline 대비 FAIL 감소 기록

## 필요 Secrets
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `AWS_ACCOUNT_ID`
- `AI_MODEL` (예: `anthropic.claude-3-haiku-20240307-v1:0`)
- `AI_API_KEY` (Bedrock 사용 시 식별값 용도로 `bedrock` 가능)

## 입력값
- `auto_merge` (bool, 기본 false)
- `skip_deploy` (bool)
- `cleanup` (bool)

## 기대 결과
1. 취약 인프라 배포 후 Prowler FAIL 다수 발생
2. 카테고리별 Remediation PR 생성
3. PR Merge 후 `apply` 실행
4. `verify` 단계에서 `baseline_fail` 대비 `post_fail` 감소 확인
5. 자동 불가 항목(`fms`, `organizations`, `root MFA`)은 로그만 기록

## 예시 로그
```text
baseline_fail=23
post_fail=6
reduced=17
```

## 주의사항
- 테스트용 AWS 계정/권한만 사용하세요.
- 노출된 PAT/AWS Access Key는 즉시 폐기(rotate)하세요.
- Root MFA는 자동 Remediation 대상이 아닙니다.
