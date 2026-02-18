# Prowler Auto Remediation Test

AWS IaC 보안 자동화를 검증하기 위한 PoC 저장소입니다.

이 저장소는 다음 3가지를 분리해서 관리합니다.
- 취약한 기준 인프라: `terraform/test_infra`
- AI/룰 기반으로 생성되는 Remediation 코드: `terraform/remediation`
- Prowler 결과 파싱, 코드 생성, 안전 적용 보조 스크립트: `iac/scripts`

## 1. 목표
- 취약 환경 Terraform을 항상 별도 보관하여 재사용 가능하게 유지
- Prowler 스캔 결과(JSON) 기반으로 Remediation Terraform 자동 생성
- 지원 카테고리만 자동 적용:
  - `iam`
  - `s3`
  - `network-ec2-vpc`
  - `cloudtrail`
  - `cloudwatch`
- Apply 멱등성(idempotency) 확보
- singleton 리소스/파괴적 변경 보호
- drift loop 및 replacement 위험 감지 시 적용 차단

## 2. 디렉토리 구조
```text
prowler-auto-remediation-test/
├─ terraform/
│  ├─ test_infra/
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  └─ outputs.tf
│  └─ remediation/
│     ├─ main.tf
│     ├─ variables.tf
│     └─ outputs.tf
├─ iac/
│  ├─ scripts/
│  │  ├─ generate_remediation.py
│  │  ├─ inject_lifecycle.py
│  │  ├─ resilient_apply.sh
│  │  └─ auto_import.sh
│  ├─ snippets/
│  │  ├─ iam/
│  │  ├─ s3/
│  │  ├─ network-ec2-vpc/
│  │  ├─ cloudtrail/
│  │  └─ cloudwatch/
│  └─ check_to_iac.yaml
├─ .github/workflows/
│  └─ prowler-security-scan.yml
├─ bootstrap_repo.py
└─ setup_github_secrets.ps1
```

## 3. 사전 준비
- Python 3.10+
- Git
- GitHub Personal Access Token (classic 권장, `repo` 권한 필요)
- GitHub CLI(`gh`) - 시크릿 자동 등록 시 필요
- AWS IAM User Access Key (PoC용 최소 권한 계정 권장)

## 4. 입력값 설명
`bootstrap_repo.py` 실행 시 아래 항목을 입력합니다.
- `GitHub Personal Access Token`: PAT 값 (`ghp_...`)
- `GitHub account/org name`: 예) `jiwonseok97`
- `Private repo?`: 보안상 `yes` 권장
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`: 예) `ap-northeast-2`
- `Multi-region environment?`: CloudTrail 시나리오 검증 목적이면 `yes` 권장
- `AI model`: Bedrock 예) `anthropic.claude-3-haiku-20240307-v1:0`
- `AI API key`: Bedrock 사용 시 실제 키 대신 `bedrock` 같은 식별값 사용 가능

## 5. 실행 절차
1. 저장소 부트스트랩 실행
```powershell
python .\bootstrap_repo.py
```

2. GitHub Actions 시크릿 등록
```powershell
.\setup_github_secrets.ps1 -Repo <owner>/prowler-auto-remediation-test
```

필수 시크릿:
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_DEFAULT_REGION`
- `AI_MODEL`
- `AI_API_KEY`

3. GitHub Actions 수동 실행
- Actions 탭 -> `Prowler Security Scan and AI Remediation` -> `Run workflow`

4. 생성된 PR 확인 및 Merge
- 브랜치명: `remediation-<run_id>`
- 변경 파일: `terraform/remediation/main.tf`, `artifacts/remediation.log` 등

5. Merge 후 apply 자동 실행 확인
- `main` push 트리거로 apply job 실행
- apply 후 Prowler 재스캔 아티팩트 업로드

## 6. 워크플로 동작 요약
`plan` job:
- `terraform/test_infra` 초기화
- Prowler 스캔 실행
- 결과 파일 아티팩트 업로드

`ai_remediation` job:
- Prowler 결과 다운로드
- `generate_remediation.py`로 snippet 기반 코드 생성
- `inject_lifecycle.py`로 `prevent_destroy`, `ignore_changes` 삽입
- `remediation-<run_id>` PR 자동 생성

`apply` job (`main` push 시):
- `auto_import.sh` 실행 (import map 존재 시)
- `resilient_apply.sh` 실행
- replacement 감지 시 차단
- drift loop 의심 시 차단
- apply 후 Prowler 재스캔 수행

## 7. 스크립트 설명
- `iac/scripts/generate_remediation.py`
  - Prowler JSON/JSONL/ASFF 형식 일부를 파싱
  - 지원 카테고리만 추출해 `terraform/remediation/main.tf` 생성
  - 미지원 항목은 로그만 남김

- `iac/scripts/inject_lifecycle.py`
  - 생성된 Terraform 리소스에 lifecycle 보호 블록 삽입

- `iac/scripts/resilient_apply.sh`
  - plan 결과에서 replacement 감지 시 즉시 실패
  - 최대 2회 apply 후 drift 잔존 여부 확인

- `iac/scripts/auto_import.sh`
  - `artifacts/import-map.txt` 존재 시 import 실행
  - import 실패 시 apply 차단

## 8. PoC 범위와 제한
- 자동 Remediation 대상은 지정된 5개 카테고리로 제한됩니다.
- 아래 유형은 자동 수정 대신 로그 처리됩니다.
  - `organizations`
  - `fms`
  - `root MFA` 관련 항목

## 9. 보안 주의사항
- PAT/AWS 키를 터미널, 채팅, 스크린샷에 노출했다면 즉시 폐기(rotate)하세요.
- 운영 계정 대신 전용 테스트 계정 사용을 권장합니다.
- `terraform/test_infra`는 의도적으로 취약한 코드이므로 운영 환경에 적용하지 마세요.
