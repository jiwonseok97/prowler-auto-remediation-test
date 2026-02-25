# Prowler Auto Remediation

> AWS 보안 취약점 자동 탐지 → 코드 생성 → 적용 → 재검증 파이프라인
> Checkov IaC 정적 분석

---

## 프로젝트 개요

Prowler(CIS 1.4 + ISMS-P)로 AWS 계정을 스캔하고, 발견된 취약점에 대한 Terraform 보안 강화 코드를 자동 생성·적용·재검증하는 End-to-End CI/CD 보안 파이프라인입니다.

- **메인 파이프라인**: Prowler 스캔 → 자동 Remediation PR 생성 → Apply → 재스캔 (01→04)
- **IaC 정적 분석**  : Checkov를 통한 Terraform 코드 보안 점검 (SARIF → GitHub Code Scanning)
- **인프라 스캐너**  : OpenVAS GMP 프로토콜 기반 네트워크 취약점 스캐너 연동
- **데모 인프라**    : 취약하게 구성한 Terraform 인프라(S3·CloudWatch·KMS·VPC 등 55건 FAIL)를 Prowler로 탐지하고, AI가 자동 생성한 수정
    Terraform을 PR·머지·Apply하여 FAIL 0건에 수렴함을 AS-IS/TO-BE로 수치 증명하는 DevSecOps 자동화 데모

---

## 전체 파이프라인 흐름

```
[취약 인프라 배포]
  terraform/vulnerable_infra_test/
  ├── main.tf          # 전체 취약 리소스 정의
  ├── variables.tf     # 취약 항목별 토글 변수
  └── terraform.tfvars # 실제 배포 수량 및 활성화 설정

[01] Scan Baseline (scan-cis.yml)
  └─ Prowler CIS 1.4 + ISMS-P 스캔
  └─ 결과: normalized_findings.json / scan_manifest.json
  └─ artifact: scan-<run_id>

[02] Generate Remediation PRs (remediate-pr.yml)
  └─ FAIL 항목 → Terraform 코드 자동 생성 (카테고리별)
  └─ PR 생성: remediation/iam, /s3, /network-ec2-vpc, /cloudtrail, /cloudwatch

[PR 수동 머지]

[03] Apply (apply-on-merge.yml)
  └─ 머지된 remediation/ Terraform 코드 적용
  └─ 기존 리소스 auto import → resilient apply

[04] Rescan & Verify (rescan-after-apply.yml)
  └─ 동일 계정 재스캔 → FAIL 감소 확인

[IaC 정적 분석] security-pipeline-iac-scanners.yml
  └─ Checkov 스캔: terraform/ + remediation/
  └─ JSON + SARIF 저장 → GitHub Code Scanning 업로드

[인프라 스캐너] security-pipeline-infra-scanner-bridges.yml
  └─ OpenVAS GMP 스캔 (OPENVAS_HOST Secrets 필요)
  └─ gvm-tools Python 라이브러리 기반
```

---

## 디렉토리 구조

```
prowler-auto-remediation-test/
│
├── .github/
│   ├── workflows/
│   │   ├── scan-cis.yml                              # [01] Prowler 스캔 + 취약 인프라 배포
│   │   ├── remediate-pr.yml                          # [02] 보안 강화 코드 자동 생성 + PR
│   │   ├── apply-on-merge.yml                        # [03] PR 머지 후 Terraform Apply
│   │   ├── rescan-after-apply.yml                    # [04] Apply 후 재스캔 검증
│   │   ├── security-pipeline-iac-scanners.yml        # Checkov IaC 정적 분석 (SARIF)
│   │   └── security-pipeline-infra-scanner-bridges.yml # OpenVAS 인프라 스캐너
│   └── assets/
│       ├── cis-logo.svg
│       └── isms-logo.png
│
├── iac/
│   ├── scripts/                                      # 자동화 Python + Shell 스크립트
│   │   ├── generate_remediation.py                   # Prowler FAIL → Terraform 코드 생성
│   │   ├── generate_remediation_bundle.py            # 번들 생성
│   │   ├── normalize_findings.py                     # 결과 정규화
│   │   ├── convert_findings.py                       # 포맷 변환
│   │   ├── compare_failures.py                       # FAIL 비교 (Before/After)
│   │   ├── create_category_prs.py                    # 카테고리별 PR 생성
│   │   ├── builder_to_manifest.py                    # 매니페스트 빌드
│   │   ├── build_category_manifest.py                # 카테고리 매니페스트
│   │   ├── write_scan_manifest.py                    # 스캔 매니페스트 기록
│   │   ├── publish_scan_to_api.py                    # Prowler App API 발행
│   │   ├── openvas_scan.py                           # OpenVAS GMP 스캔 자동화
│   │   ├── infra_bridge_report.py                    # 인프라 스캐너 브릿지 리포트
│   │   ├── osfp_score.py                             # OSFP 점수 계산
│   │   ├── resilient_apply.sh                        # 카테고리별 Terraform Apply (장애 허용)
│   │   ├── auto_import.sh                            # Terraform import 자동화
│   │   ├── validate_generated_tf.sh                  # 생성 Terraform 유효성 검사
│   │   ├── apply_merged_remediation.sh               # 머지된 remediation Apply
│   │   └── backup_aws_runtime_state.sh               # AWS 런타임 상태 백업
│   ├── snippets/                                     # Terraform 보안 강화 템플릿
│   │   ├── check_map.yaml                            # Check ID → 스니펫 매핑
│   │   ├── iam/
│   │   ├── s3/
│   │   ├── cloudtrail/
│   │   ├── cloudwatch/
│   │   └── network-ec2-vpc/
│   └── compliance/
│       └── isms_p_checks.txt                         # ISMS-P 추가 점검 항목
│
├── terraform/
│   └── vulnerable_infra_test/                        # AS-IS 데모용 의도적 취약 인프라
│       ├── main.tf                                   # SG 90개 + S3 20개 (취약 설정)
│       ├── variables.tf                              # security_group_count=90, vuln_bucket_count=20
│       ├── terraform.tfvars
│       ├── outputs.tf
│       └── backend.tf                                # backend "local"
│
├── remediation/                                      # 자동 생성된 보안 강화 Terraform (116개)
│   ├── manifest.json
│   ├── iam/                                          # IAM 강화 코드 + import-map.txt
│   ├── s3/                                           # S3 강화 코드 + import-map.txt
│   ├── cloudtrail/                                   # CloudTrail 강화 코드
│   ├── cloudwatch/                                   # CloudWatch 강화 코드
│   └── network-ec2-vpc/                              # SG/VPC 강화 코드
│
├── reports/
│   ├── checkov/                                      # Checkov 스캔 원본 결과
│   │   ├── checkov-terraform.json                    # 취약 코드 스캔 결과 (JSON)
│   │   ├── checkov-terraform.sarif                   # SARIF (GitHub Code Scanning)
│   │   ├── checkov-terraform-cli.txt                 # CLI 출력
│   │   ├── checkov-remediation.json                  # 강화 코드 스캔 결과 (JSON)
│   │   ├── checkov-remediation.sarif
│   │   └── checkov-remediation-cli.txt
│   ├── checkov-notion.md                             # Checkov 보고서 (고유 취약점 25종 기준)
│   ├── security-scanner-benefits-report.html         # 스캐너 도입 효과 증명 보고서 (HTML)
│   ├── SECURITY_SCANNER_REPORT_2026-02-24.md
│   ├── generate_notion_md.py                         # Notion MD 생성 스크립트
│   └── generate_report.py                            # HTML 보고서 생성 스크립트
│
├── docs/
│   ├── WEEK_SPRINT_02W4.md                           # 주간 스프린트 계획 (02/24~02/28)
│   ├── VULNERABLE_INFRA_BEFORE_AFTER_DEMO_GUIDE.md   # AS-IS/TO-BE 데모 가이드
│   ├── PROWLER_OSS_PIPELINE_BRIDGE_GUIDE.md          # Prowler 파이프라인 브릿지 가이드
│   └── PROWLER_PIPELINE_AUTOTRIGGER_GUIDE.md         # 파이프라인 자동 트리거 가이드
│
├── iam/
│   └── bedrock-minimum-policy.json                   # Bedrock 최소 권한 IAM 정책
│
├── local/
│   ├── tmp/                                          # 임시 파일
│   └── trust-policy.json                             # OIDC Trust Policy 초안
│
├── .env.example                                      # 환경변수 예시
└── README.md
```

---

## GitHub Secrets 설정

### 필수 (메인 파이프라인)

| Secret | 예시 값 | 설명 |
| --- | --- | --- |
| `AWS_OIDC_ROLE_ARN` | `arn:aws:iam::123456789012:role/GitHubActionsRole` | AWS OIDC 인증 Role |

### 선택 (Prowler App 연동)

| Secret | 설명 |
| --- | --- |
| `PROWLER_APP_API_URL` | Prowler App 결과 발행 엔드포인트 |
| `PROWLER_APP_API_TOKEN` | Bearer 토큰 |

### 선택 (OpenVAS 인프라 스캐너)

| Secret | 예시 값 | 설명 |
| --- | --- | --- |
| `OPENVAS_HOST` | `10.0.0.5` | GVM 서버 IP |
| `OPENVAS_PORT` | `9390` | GMP TLS 포트 |
| `OPENVAS_USERNAME` | `admin` | 로그인 사용자 |
| `OPENVAS_PASSWORD` | (필수) | 로그인 비밀번호 |

> OpenVAS Secrets 미설정 시 워크플로우가 graceful skip 처리됩니다.

### GitHub Actions 권한 설정

Repository Settings → Actions → General:
- Workflow permissions: `Read and write permissions`
- `Allow GitHub Actions to create and approve pull requests` 활성화

---

## 워크플로우 상세

### 01 — scan-cis.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | `workflow_dispatch` |
| 입력 | `account_id`, `deploy_vulnerable` (bool) |
| 주요 기능 | Prowler CIS 1.4 + ISMS-P 스캔, 취약 인프라 배포/정리 |
| 누적 방지 | pre-deploy 단계에서 태그(`ProwlerDemo=vulnerable_infra_test`) 기반 기존 리소스 삭제 |

### 02 — remediate-pr.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | `workflow_dispatch` (scan_run_id 입력) |
| 주요 기능 | FAIL 항목 → Terraform 코드 생성 → 카테고리별 PR 생성 |
| PR 브랜치 | `remediation/iam`, `/s3`, `/network-ec2-vpc`, `/cloudtrail`, `/cloudwatch` |

### 03 — apply-on-merge.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | `push to main` (PR 머지) |
| 주요 기능 | 머지된 remediation/ Terraform Apply (카테고리 격리, 부분 실패 허용) |

### 04 — rescan-after-apply.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | 03 Apply 완료 후 자동 실행 |
| 성공 조건 | `post_fail < baseline_fail` |

### IaC 스캐너 — security-pipeline-iac-scanners.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | `workflow_dispatch` |
| 도구 | Checkov 3.2.506 |
| 출력 | JSON + SARIF → GitHub Code Scanning 업로드 |
| 결과 | [reports/checkov-notion.md](reports/checkov-notion.md) |

### 인프라 스캐너 — security-pipeline-infra-scanner-bridges.yml

| 항목 | 내용 |
| --- | --- |
| 트리거 | `workflow_dispatch` |
| 도구 | OpenVAS (GVM/GMP 프로토콜) |
| 스크립트 | `iac/scripts/openvas_scan.py` |
| Secrets 없을 시 | graceful skip |

---

## Checkov IaC 스캔 결과 요약

> 상세 보고서: [reports/checkov-notion.md](reports/checkov-notion.md)

| 지표 | Before (취약 코드) | After (강화 코드) |
| --- | --- | --- |
| 고유 취약점 유형 | **25종** | **0종** |
| 보안 점검 통과율 | **16.7%** (5/30종) | **100%** (9/9종) |
| 영향받는 리소스 | **111개** (SG 90 + S3 20 + IAM 1) | **0개** |

### 취약점 카테고리

| 카테고리 | 유형 수 | 최고 위험도 |
| --- | --- | --- |
| Security Group | 7종 (90개 SG) | CRITICAL |
| S3 버킷 보안 | 11종 (20개 S3) | CRITICAL |
| IAM 패스워드 정책 | 7종 | HIGH |

---

## 자동 보안 강화 범위

| 카테고리 | 내용 |
| --- | --- |
| IAM | 패스워드 정책, Config Recorder |
| S3 | Public Access Block, KMS 암호화, 버저닝, 액세스 로깅 |
| CloudTrail | CloudWatch 로깅 연동 |
| CloudWatch | 로그 그룹, 메트릭 필터, 알람 |
| EC2 / VPC | Security Group 규칙, VPC Flow Logs, Network ACL |

지원 범위 외 항목은 `SKIPPED` 처리 (파이프라인 중단 없음).

---

## 주의사항

| 항목 | 내용 |
| --- | --- |
| AWS 비용 | SG 90개 + S3 20개 데모 인프라 → 데모 후 즉시 `terraform destroy` 실행 |
| 리소스 누적 방지 | scan-cis.yml의 pre-deploy cleanup이 자동으로 기존 리소스 삭제 (태그 기반) |
| OpenVAS 미연결 | Secrets 미설정 시 스캐너 워크플로우 자동 skip |
| Docker 리소스 | Prowler 컨테이너와 OpenVAS 컨테이너 동시 실행 금지 |
| backend "local" | `terraform/vulnerable_infra_test`는 local 백엔드 사용 (CI에서 상태 비유지 → pre-cleanup 필수) |

---

## 관련 링크

| 항목 | 링크 |
| --- | --- |
| GitHub Actions | https://github.com/jiwonseok97/prowler-auto-remediation/actions |
| Checkov 보고서 | https://github.com/jiwonseok97/prowler-auto-remediation/blob/main/reports/checkov-notion.md |
| GitHub Code Scanning | Security 탭 → Code scanning alerts |
| Prowler App UI | http://localhost:3000 |
