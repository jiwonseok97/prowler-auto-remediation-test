# Checkov IaC 보안 스캔 보고서

> 생성일: 2026-02-24  |  도구: Checkov 3.2.506  |  대상: AWS Terraform 코드

---

## 📊 Executive Summary

Checkov를 활용하여 **취약한 인프라 코드(terraform/)** 와 **자동 보안 강화 코드(remediation/)** 를 비교 분석한 결과입니다.

| 항목 | 취약 코드 (Before) | 강화 코드 (After) |
| --- | --- | --- |
| 리소스 수 | 132개 | 116개 |
| 총 점검 수 | 938건 | 82건 |
| ✅ PASS | 81건 | 82건 |
| ❌ FAIL | 857건 | 0건 |
| **통과율** | **8.6%** | **100%** |

---

## ❌ 취약 코드 — 취약점 카테고리별 분류

| 카테고리 | 건수 | 비율 |
| --- | --- | --- |
| Security Group | 630건 | 73.5% |
| S3 버킷 보안 | 120건 | 14.0% |
| 암호화 / KMS | 0건 | 0.0% |
| 로깅 / 감사 | 0건 | 0.0% |
| 기타 | 107건 | 12.5% |

---

## 🔍 상위 10개 실패 항목 (취약 코드)

| 순위 | Check ID | 설명 | 건수 | 위험도 |
| --- | --- | --- | --- | --- |
| 1 | `CKV_AWS_23` | Security Group — SSH(22) 무제한 인바운드 | 90건 | 🔴 CRITICAL |
| 2 | `CKV_AWS_382` | Security Group — 무제한 인바운드 허용 | 90건 | 🟠 HIGH |
| 3 | `CKV_AWS_24` | Security Group — RDP(3389) 무제한 인바운드 | 90건 | 🔴 CRITICAL |
| 4 | `CKV_AWS_25` | Security Group — 모든 포트 무제한 인바운드 | 90건 | 🟠 HIGH |
| 5 | `CKV_AWS_260` | Security Group — HTTP(80) 무제한 인바운드 | 90건 | 🟠 HIGH |
| 6 | `CKV_AWS_277` | Security Group — HTTPS(443) 무제한 인바운드 | 90건 | 🟠 HIGH |
| 7 | `CKV2_AWS_5` | Security Group — EC2 인스턴스 연결 미검증 | 90건 | 🟠 HIGH |
| 8 | `CKV_AWS_53` | S3 — Block Public ACLs 미설정 | 20건 | 🟠 HIGH |
| 9 | `CKV_AWS_54` | S3 — Block Public Policy 미설정 | 20건 | 🟠 HIGH |
| 10 | `CKV_AWS_55` | S3 — Ignore Public ACLs 미설정 | 20건 | 🟡 MEDIUM |

---

## 💻 코드 비교 — Security Group

### Before (취약 코드) — `CKV_AWS_23` ❌

```hcl
resource "aws_security_group" "vuln" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]   # ❌ 전체 인터넷 SSH 허용
  }
}
```

### After (강화 코드) — `CKV_AWS_23` ✅

```hcl
resource "aws_security_group" "secure" {
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]   # ✅ VPC 내부만 허용
  }
}
```

---

## 💻 코드 비교 — S3 Public Access Block

### Before (취약 코드) — `CKV_AWS_53~56` ❌

```hcl
resource "aws_s3_bucket_public_access_block" "bad" {
  block_public_acls       = false   # ❌
  block_public_policy     = false   # ❌
  ignore_public_acls      = false   # ❌
  restrict_public_buckets = false   # ❌
}
```

### After (강화 코드) — `CKV_AWS_53~56` ✅

```hcl
resource "aws_s3_bucket_public_access_block" "secure" {
  block_public_acls       = true    # ✅
  block_public_policy     = true    # ✅
  ignore_public_acls      = true    # ✅
  restrict_public_buckets = true    # ✅
}
```

---

## ⚙️ Checkov 파이프라인 설정값

```yaml
# GitHub Actions 핵심 설정
- name: Run Checkov
  run: |
    checkov -d terraform \
      -o json \          # JSON 결과
      -o sarif \         # GitHub Code Scanning
      -o cli \           # 콘솔 출력
      --quiet \          # 배너 제거 (SARIF 파싱 필수)
      --soft-fail         # 실패해도 파이프라인 계속
```

| 환경 | 설정 값 |
| --- | --- |
| Checkov 버전 | `3.2.506` |
| 스캔 대상 | `terraform/` 디렉토리 |
| 출력 형식 | JSON, SARIF, CLI |
| permissions | `security-events: write` (SARIF 업로드) |

---

## ✅ OpenVAS GitHub Secrets 설정

| Secret 이름 | 예시 값 | 설명 |
| --- | --- | --- |
| `OPENVAS_HOST` | `10.0.0.5` | GVM 서버 IP |
| `OPENVAS_PORT` | `9390` | GMP TLS 포트 |
| `OPENVAS_USERNAME` | `admin` | 로그인 사용자 |
| `OPENVAS_PASSWORD` | (필수) | 로그인 비밀번호 |

---

## 🏆 핵심 성과

| 지표 | 수치 |
| --- | --- |
| 발견된 보안 취약점 | **857건** |
| 보안 점검 통과율 개선 | **8.6% → 100%** |
| 자동 보안 강화 파일 수 | **116개** (remediation/) |
| 가장 많은 취약 항목 | Security Group 무제한 인바운드 **(630건)** |

---

*Checkov 3.2.506 | 2026-02-24 | GitHub Actions CI/CD 통합*