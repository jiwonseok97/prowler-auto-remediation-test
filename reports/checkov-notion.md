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
| **통과율** | **81 ÷ 938 = 8.6%** | **82 ÷ 82 = 100%** |

---

## ❌ 취약 코드 — 리소스별 실패 건수 계산

```
aws_security_group               90개 ×  7개 체크 =  630건
aws_s3_bucket 관련               20개 × 11개 체크 =  220건
aws_iam_account_password_policy   1개 ×  7개 체크 =    7건
                                 ─────────────────────────
합계                                                 857건
```

| 리소스 | 개수 | 적용 체크 수 | 계산식 |
| --- | --- | --- | --- |
| `aws_security_group` | 90개 | 7개 | 90 × 7 = **630건** |
| `aws_s3_bucket` 관련 | 20개 | 11개 | 20 × 11 = **220건** |
| `aws_iam_account_password_policy` | 1개 | 7개 | 1 × 7 = **7건** |
| **합계** | | | **630 + 220 + 7 = 857건** |

### Security Group — 7개 체크 상세 (90개 × 7 = 630건)

| Check ID | 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_23` | SSH(22) 무제한 인바운드 (0.0.0.0/0) | 🔴 CRITICAL |
| `CKV_AWS_24` | RDP(3389) 무제한 인바운드 (0.0.0.0/0) | 🔴 CRITICAL |
| `CKV_AWS_25` | 모든 포트 무제한 인바운드 | 🟠 HIGH |
| `CKV_AWS_260` | HTTP(80) 무제한 인바운드 | 🟠 HIGH |
| `CKV_AWS_277` | HTTPS(443) 무제한 인바운드 | 🟠 HIGH |
| `CKV_AWS_382` | 무제한 인바운드 허용 | 🟠 HIGH |
| `CKV2_AWS_5` | EC2 인스턴스 연결 미검증 | 🟠 HIGH |

### S3 버킷 관련 — 11개 체크 상세 (20개 × 11 = 220건)

| Check ID | 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_53` | Block Public ACLs 미설정 | 🟠 HIGH |
| `CKV_AWS_54` | Block Public Policy 미설정 | 🟠 HIGH |
| `CKV_AWS_55` | Ignore Public ACLs 미설정 | 🟠 HIGH |
| `CKV_AWS_56` | Restrict Public Buckets 미설정 | 🟠 HIGH |
| `CKV_AWS_18` | 액세스 로깅 미설정 | 🟡 MEDIUM |
| `CKV_AWS_21` | 버저닝 미설정 | 🟡 MEDIUM |
| `CKV_AWS_144` | 크로스 리전 복제 미설정 | 🟡 MEDIUM |
| `CKV_AWS_145` | KMS 암호화 미설정 | 🟠 HIGH |
| `CKV2_AWS_6` | Public Access Block 누락 | 🟠 HIGH |
| `CKV2_AWS_61` | 수명 주기 정책 미설정 | 🟡 MEDIUM |
| `CKV2_AWS_62` | 이벤트 알림 미설정 | 🟡 MEDIUM |

### IAM 패스워드 정책 — 7개 체크 상세 (1개 × 7 = 7건)

| Check ID | 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_9` | 비밀번호 만료 정책 미설정 | 🟡 MEDIUM |
| `CKV_AWS_10` | 비밀번호 재사용 제한 미설정 | 🟡 MEDIUM |
| `CKV_AWS_11` | 대문자 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_12` | 소문자 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_13` | 숫자 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_14` | 특수문자 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_15` | 최소 길이 14자 미달 | 🟡 MEDIUM |

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
| 발견된 보안 취약점 | **857건** (630 + 220 + 7) |
| 보안 점검 통과율 개선 | **8.6% → 100%** (81/938 → 82/82) |
| 자동 보안 강화 파일 수 | **116개** (remediation/) |
| 최다 실패 리소스 | Security Group 90개 × 7체크 = **630건** |

---

*Checkov 3.2.506 | 2026-02-24 | GitHub Actions CI/CD 통합*
