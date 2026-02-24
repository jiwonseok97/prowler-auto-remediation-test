# Security Scanner 도입 이점 증명 보고서

> **작성일**: 2026-02-24
> **스캐너**: Checkov v3.2.506 (IaC) + OpenVAS/GVM (인프라)
> **파이프라인**: GitHub Actions CI/CD

---

## 1. 개요

본 보고서는 **Checkov IaC 정적 분석 스캐너**와 **OpenVAS 인프라 취약점 스캐너**를 GitHub Actions 파이프라인에 통합한 결과를 증명합니다.

### 핵심 성과

| 지표 | 수치 |
|------|------|
| 발견된 보안 취약점 (Checkov) | **857건** |
| 보안 점검 통과율: 취약 코드 | **8.6%** (81/938) |
| 보안 점검 통과율: 강화 코드 | **100%** (82/82) |
| 자동 보안 강화 파일 수 | **116개** (remediation/) |
| 통합 파이프라인 단계 | **6단계** |

---

## 2. Checkov IaC 스캔 결과

### 2.1 취약한 코드 (terraform/)

```
checkov -d terraform -o json -o sarif --quiet --output-file-path artifacts/iac-scanners --soft-fail
```

| 항목 | 수치 |
|------|------|
| 리소스 수 | 132개 |
| 총 점검 수 | 938건 |
| **PASS** | **81건 (8.6%)** |
| **FAIL** | **857건 (91.4%)** |
| SKIP | 0건 |

### 2.2 자동 보안 강화 코드 (remediation/)

```
checkov -d remediation -o json -o sarif --quiet --output-file-path artifacts/iac-scanners --soft-fail
```

| 항목 | 수치 |
|------|------|
| 리소스 수 | 116개 |
| 총 점검 수 | 82건 |
| **PASS** | **82건 (100%)** |
| **FAIL** | **0건 (0%)** |

### 2.3 상위 실패 체크 항목

| Check ID | 설명 | 건수 | 위험도 |
|----------|------|-----:|--------|
| CKV_AWS_23 | Security Group - SSH(22) 무제한 인바운드 허용 | 90 | CRITICAL |
| CKV_AWS_24 | Security Group - RDP(3389) 무제한 인바운드 허용 | 90 | CRITICAL |
| CKV_AWS_25 | Security Group - 무제한 인바운드 허용 | 90 | HIGH |
| CKV_AWS_260 | Security Group - HTTP(80) 무제한 인바운드 허용 | 90 | HIGH |
| CKV_AWS_277 | Security Group - 무제한 인바운드 허용 | 90 | HIGH |
| CKV_AWS_382 | Security Group - 무제한 인바운드 허용 | 90 | HIGH |
| CKV2_AWS_5 | Security Group - EC2 인스턴스 연결 미검증 | 90 | HIGH |
| CKV_AWS_53 | S3 - Block Public ACLs 비활성화 | 20 | HIGH |
| CKV_AWS_54 | S3 - Block Public Policy 비활성화 | 20 | HIGH |
| CKV_AWS_55 | S3 - Ignore Public ACLs 비활성화 | 20 | MEDIUM |

### 2.4 취약점 카테고리 분류

| 카테고리 | 건수 | 비율 |
|----------|-----:|-----:|
| Security Group (네트워크 접근) | 630건 | 73.5% |
| S3 버킷 보안 | 80건 | 9.3% |
| 암호화 / KMS | - | - |
| 로깅 / 감사 | - | - |
| 기타 | 147건 | 17.2% |

---

## 3. 코드 비교 증거

### 3.1 Security Group — 취약 코드 vs. 보안 강화 코드

**BEFORE (취약한 코드 — CKV_AWS_23 FAIL):**
```hcl
resource "aws_security_group" "vuln" {
  name   = "vulnerable-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from anywhere"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # ❌ 전체 인터넷 SSH 허용
  }
}
```

**AFTER (보안 강화 코드 — CKV_AWS_23 PASS):**
```hcl
resource "aws_security_group" "secure" {
  name   = "secure-sg"
  vpc_id = var.vpc_id

  ingress {
    description = "SSH from VPC only"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # ✅ VPC 내부만 허용
  }
}
```

### 3.2 S3 Public Access Block — 취약 코드 vs. 보안 강화 코드

**BEFORE (취약한 코드 — CKV_AWS_53/54/55/56 FAIL):**
```hcl
resource "aws_s3_bucket_public_access_block" "vuln_bucket_pab" {
  count                   = var.vuln_bucket_count
  bucket                  = aws_s3_bucket.vuln_bucket[count.index].id
  block_public_acls       = false  # ❌ 퍼블릭 ACL 허용
  block_public_policy     = false  # ❌ 퍼블릭 정책 허용
  ignore_public_acls      = false  # ❌ 퍼블릭 ACL 무시 안 함
  restrict_public_buckets = false  # ❌ 퍼블릭 버킷 허용
}
```

**AFTER (보안 강화 코드 — CKV_AWS_53/54/55/56 PASS):**
```hcl
resource "aws_s3_bucket_public_access_block" "secure_bucket_pab" {
  bucket                  = aws_s3_bucket.secure_bucket.id
  block_public_acls       = true   # ✅ 퍼블릭 ACL 차단
  block_public_policy     = true   # ✅ 퍼블릭 정책 차단
  ignore_public_acls      = true   # ✅ 퍼블릭 ACL 무시
  restrict_public_buckets = true   # ✅ 퍼블릭 버킷 제한
}
```

---

## 4. Checkov 설정 가이드

### 4.1 GitHub Actions 워크플로우 설정

**파일**: `.github/workflows/security-pipeline-iac-scanners.yml`

```yaml
name: Security Pipeline - IaC Scanners (Checkov)

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: read
  security-events: write    # GitHub Code Scanning SARIF 업로드 필수

jobs:
  checkov-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Install Checkov
        run: |
          python -m pip install --upgrade pip
          pip install checkov==3.2.506

      - name: Run Checkov on Terraform (취약 코드)
        run: |
          checkov -d terraform \
            -o json \
            -o sarif \
            -o cli \
            --quiet \
            --output-file-path artifacts/iac-scanners \
            --soft-fail

      - name: Run Checkov on Remediation (강화 코드 검증)
        run: |
          checkov -d remediation \
            -o json \
            -o sarif \
            --quiet \
            --output-file-path artifacts/iac-scanners/remediation \
            --soft-fail

      - name: Upload SARIF to GitHub Code Scanning
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: artifacts/iac-scanners/results.sarif.json
          category: checkov-terraform

      - name: Upload Artifacts
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: checkov-reports-${{ github.run_id }}
          path: artifacts/iac-scanners/
```

### 4.2 주요 Checkov 옵션

| 옵션 | 값 | 설명 |
|------|-----|------|
| `-d` | `terraform` | 스캔 대상 디렉토리 |
| `-o` | `json sarif cli` | 출력 형식 (복수 지정 가능) |
| `--quiet` | - | ASCII 아트 배너 제거 (SARIF 파싱 필수) |
| `--soft-fail` | - | 취약점 발견 시에도 exit code 0 (파이프라인 계속 진행) |
| `--output-file-path` | `artifacts/` | 결과 파일 저장 경로 |
| `--check` | `CKV_AWS_*` | 특정 체크만 실행 (선택적) |
| `--skip-check` | `CKV_AWS_*` | 특정 체크 제외 (선택적) |

---

## 5. OpenVAS 설정 가이드

### 5.1 GitHub Actions 워크플로우 설정

**파일**: `.github/workflows/security-pipeline-infra-scanner-bridges.yml`

```yaml
name: Security Pipeline - Infra Scanner Bridges (OpenVAS)

on:
  workflow_dispatch:
    inputs:
      target_host:
        description: "스캔 대상 IP 또는 FQDN (필수)"
        required: true
        type: string
      openvas_timeout:
        description: "OpenVAS 스캔 최대 대기 시간(초)"
        required: false
        type: string
        default: "3600"

jobs:
  openvas-scan:
    runs-on: ubuntu-latest
    env:
      OPENVAS_HOST:        ${{ secrets.OPENVAS_HOST }}
      OPENVAS_PORT:        ${{ secrets.OPENVAS_PORT }}
      OPENVAS_USERNAME:    ${{ secrets.OPENVAS_USERNAME }}
      OPENVAS_PASSWORD:    ${{ secrets.OPENVAS_PASSWORD }}
      OPENVAS_TARGET:      ${{ inputs.target_host }}
      OPENVAS_TIMEOUT_SEC: ${{ inputs.openvas_timeout }}
    steps:
      - uses: actions/checkout@v4

      - name: Install gvm-tools
        run: pip install gvm-tools

      - name: Run OpenVAS scan (GMP)
        run: python iac/scripts/openvas_scan.py
```

### 5.2 GitHub Secrets 설정

| Secret 이름 | 예시 값 | 설명 |
|-------------|---------|------|
| `OPENVAS_HOST` | `10.0.0.5` | GVM 서버 IP 또는 FQDN |
| `OPENVAS_PORT` | `9390` | GMP TLS 포트 (기본값) |
| `OPENVAS_USERNAME` | `admin` | GVM 로그인 사용자 |
| `OPENVAS_PASSWORD` | `(필수)` | GVM 로그인 비밀번호 |
| `NESSUS_URL` | `https://nessus.internal:8834` | Nessus API URL (선택) |
| `NESSUS_ACCESS_KEY` | `(필수)` | Nessus API Access Key |
| `NESSUS_SECRET_KEY` | `(필수)` | Nessus API Secret Key |
| `QUALYS_API_URL` | `https://qualysapi.qualys.com` | Qualys API 엔드포인트 |
| `QUALYS_USERNAME` | `(필수)` | Qualys 사용자명 |
| `QUALYS_PASSWORD` | `(필수)` | Qualys 비밀번호 |
| `INSIGHTVM_URL` | `https://insightvm.internal:3780` | InsightVM API URL |
| `INSIGHTVM_API_KEY` | `(필수)` | InsightVM API Key |

### 5.3 OpenVAS 핵심 UUID 설정값

| 설정 항목 | UUID 값 | 설명 |
|-----------|---------|------|
| 스캔 설정 | `daba56c8-73ec-11df-a475-002264764cea` | Full and Fast 스캔 (표준 GVM) |
| 스캐너 | `08b69003-5fc2-4037-a479-93b440211c73` | OpenVAS Default Scanner |
| 포트 목록 | `33d0cd82-57c6-11e1-8ed1-406186ea4fc5` | All IANA Assigned TCP |
| 보고서 형식 | `a994b278-1f62-11e1-96ac-406186ea4fc5` | XML 형식 |

### 5.4 CVSS 위험도 분류 기준

| 등급 | CVSS 점수 | 조치 우선순위 |
|------|-----------|--------------|
| CRITICAL | 9.0 ~ 10.0 | 즉시 조치 (24시간 이내) |
| HIGH | 7.0 ~ 8.9 | 우선 조치 (7일 이내) |
| MEDIUM | 4.0 ~ 6.9 | 계획적 조치 (30일 이내) |
| LOW | 0.1 ~ 3.9 | 모니터링 후 조치 |
| INFO | 0.0 | 정보성 (조치 불필요) |

---

## 6. 통합 보안 파이프라인 아키텍처

```
개발자 PR 생성
     │
     ▼
┌─────────────────────────────────┐
│  1. Checkov IaC 정적 분석       │
│     - terraform/ 스캔           │
│     - SARIF → GitHub Code Scan  │
│     - Before/After 비교 요약    │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  2. Prowler App 클라우드 점검   │
│     - CIS AWS Benchmark         │
│     - scan-cis.yml 자동 트리거  │
│     - 결과 ZIP 업로드           │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  3. 자동 보안 강화 (remediation)│
│     - 취약점별 강화 .tf 생성    │
│     - 116개 파일, 0 FAIL 검증   │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  4. OpenVAS 런타임 스캔 (선택)  │
│     - GMP 프로토콜 자동화       │
│     - CVE 매핑 및 위험도 분류   │
│     - Nessus/Qualys 브리지      │
└─────────────────────────────────┘
     │
     ▼
┌─────────────────────────────────┐
│  5. 아티팩트 저장 및 보고       │
│     - JSON + SARIF + Markdown   │
│     - GitHub Actions Summary    │
└─────────────────────────────────┘
```

---

## 7. 도입 이점 요약

### Checkov IaC 스캐너
- **Shift-Left 보안**: 인프라 배포 전 취약점 조기 발견 → 운영 비용 절감
- **857건 자동 감지**: 수동 코드 리뷰 없이 즉시 피드백 제공
- **SARIF 통합**: GitHub Code Scanning 탭에서 개발자가 직접 취약점 확인
- **Before/After 검증**: 취약 코드 8.6% → 강화 코드 100% 통과율 증명
- **CI/CD 자동화**: 모든 PR/Push에 자동 실행 (인간 개입 불필요)
- **규정 준수**: CIS AWS Benchmark, PCI-DSS, HIPAA, SOC2 체크 내장

### OpenVAS 인프라 스캐너
- **런타임 취약점 탐지**: 배포 후 실제 서비스 대상 스캔 (IaC로 발견 못한 취약점)
- **CVE 데이터베이스 연동**: 최신 CVE 자동 매핑 및 CVSS 점수 분류
- **GMP 완전 자동화**: Python API로 스캔 생성/실행/폴링/결과수집 자동화
- **다중 스캐너 지원**: OpenVAS + Nessus + Qualys + InsightVM 브리지 연동
- **파이프라인 통합**: GitHub Actions에서 스캔 트리거 → 결과 아티팩트 저장

---

## 8. 생성된 파일 목록

| 파일 | 설명 |
|------|------|
| `reports/checkov/checkov-terraform.json` | Checkov 취약 코드 스캔 결과 (JSON) |
| `reports/checkov/checkov-terraform.sarif` | Checkov SARIF (GitHub Code Scanning) |
| `reports/checkov/checkov-terraform-cli.txt` | Checkov CLI 출력 |
| `reports/checkov/checkov-remediation.json` | Checkov 강화 코드 스캔 결과 (JSON) |
| `reports/checkov/checkov-remediation.sarif` | Checkov 강화 코드 SARIF |
| `reports/security-scanner-benefits-report.html` | 이점 증명 HTML 보고서 (시각화) |
| `iac/scripts/openvas_scan.py` | OpenVAS GMP 스캔 Python 스크립트 |
| `.github/workflows/security-pipeline-iac-scanners.yml` | Checkov 파이프라인 워크플로우 |
| `.github/workflows/security-pipeline-infra-scanner-bridges.yml` | OpenVAS 파이프라인 워크플로우 |

---

*보고서 생성: 2026-02-24 | Checkov v3.2.506 | GitHub Actions CI/CD 통합*
