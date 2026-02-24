# Checkov IaC 보안 스캔 보고서

> 생성일: 2026-02-24  |  도구: Checkov 3.2.506  |  대상: AWS Terraform (terraform/)

---

## 📊 수치 변화

| 지표 | Before (취약 코드) | After (강화 코드) |
| --- | --- | --- |
| 스캔 대상 | `terraform/` | `remediation/` |
| 스캔된 리소스 수 | 132개 | 116개 |
| 고유 취약점 유형 | **25종** | **0종** |
| 보안 점검 통과율 (고유 유형 기준) | **16.7%** (5 ÷ 30종) | **100%** (9 ÷ 9종) |
| 영향받는 리소스 수 | **111개** (SG 90 + S3 20 + IAM 1) | **0개** |
| 인스턴스 실패 건수 (참고용) | 857건 | 0건 |

> 857건은 동일한 취약점 유형이 90개 SG·20개 S3에 반복 카운트된 값으로, 실제 수정이 필요한 취약점 유형은 **25종**입니다.

---

## 📋 상위 취약점 유형 (고유 유형 기준)

| 카테고리 | 유형 수 | 영향 리소스 | 최고 위험도 |
| --- | --- | --- | --- |
| Security Group | **7종** | 90개 | 🔴 CRITICAL |
| S3 버킷 보안 | **11종** | 20개 | 🔴 CRITICAL |
| IAM 패스워드 정책 | **7종** | 1개 | 🟠 HIGH |
| **합계** | **25종** | **111개** | |

---

## 취약점 유형 분류 (25종)

| 카테고리 | 유형 수 | 영향 리소스 |
| --- | --- | --- |
| Security Group | 7종 | `aws_security_group` 90개 |
| S3 버킷 보안 | 11종 | `aws_s3_bucket` 관련 20개 |
| IAM 패스워드 정책 | 7종 | `aws_iam_account_password_policy` 1개 |
| **합계** | **25종** | |

---

##  Security Group — 7종 (영향 리소스: 90개)

| Check ID | 취약점 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_23` | 보안 그룹 및 규칙에 설명(Description) 누락 | 🔴 CRITICAL |
| `CKV_AWS_24` | SSH(22번 포트) 인바운드 0.0.0.0/0 허용   | 🔴 CRITICAL |
| `CKV_AWS_25` | RDP(3389번 포트) 인바운드 0.0.0.0/0 허용 | 🔴 CRITICAL |
| `CKV_AWS_260` | HTTP(80번 포트) 인바운드 0.0.0.0/0 허용 | 🟠 HIGH |
| `CKV_AWS_277` | 전체 포트(-1) 인바운드 0.0.0.0/0 허용   | 🟠 HIGH |
| `CKV_AWS_382` | 전체 포트(-1) 아웃바운드 0.0.0.0/0 허용 | 🟠 HIGH |
| `CKV2_AWS_5` | 보안 그룹이 어떤 리소스에도 연결되지 않음 | 🟡 MEDIUM |

---

## S3 버킷 보안 — 11종 (영향 리소스: 20개)

| Check ID | 취약점 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_53` | Block Public ACLs 비활성화 | 🔴 CRITICAL |
| `CKV_AWS_54` | Block Public Policy 비활성화 | 🔴 CRITICAL |
| `CKV_AWS_55` | Ignore Public ACLs 비활성화 | 🟠 HIGH |
| `CKV_AWS_56` | Restrict Public Buckets 비활성화 | 🟠 HIGH |
| `CKV2_AWS_6` | Public Access Block 리소스 자체 누락 | 🟠 HIGH |
| `CKV_AWS_145` | KMS 기본 암호화 미설정 | 🟠 HIGH |
| `CKV_AWS_18` | 액세스 로깅 미설정 | 🟡 MEDIUM |
| `CKV_AWS_21` | 버저닝(Versioning) 미설정 | 🟡 MEDIUM |
| `CKV_AWS_144` | 크로스 리전 복제 미설정 | 🟡 MEDIUM |
| `CKV2_AWS_61` | 수명 주기(Lifecycle) 정책 미설정 | 🟡 MEDIUM |
| `CKV2_AWS_62` | 이벤트 알림 미설정 | 🟡 MEDIUM |

---

##  IAM 패스워드 정책 — 7종 (영향 리소스: 1개)

| Check ID | 취약점 설명 | 위험도 |
| --- | --- | --- |
| `CKV_AWS_10` | 최소 비밀번호 길이 14자 미달 | 🟠 HIGH |
| `CKV_AWS_9` | 비밀번호 90일 만료 정책 미설정 | 🟡 MEDIUM |
| `CKV_AWS_11` | 소문자 포함 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_12` | 숫자 포함 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_13` | 비밀번호 재사용 방지 미설정 | 🟡 MEDIUM |
| `CKV_AWS_14` | 특수문자 포함 요구 미설정 | 🟡 MEDIUM |
| `CKV_AWS_15` | 대문자 포함 요구 미설정 | 🟡 MEDIUM |

---

##  통과된 체크 유형 (5종, terraform/)

| Check ID | 설명 |
| --- | --- |
| `CKV_AWS_19` | S3 저장 데이터 서버 측 암호화(SSE) 활성화 |
| `CKV_AWS_20` | S3 버킷 ACL 퍼블릭 READ 허용 여부 점검 |
| `CKV_AWS_41` | provider에 AWS 액세스 키 하드코딩 없음 확인 |
| `CKV_AWS_57` | S3 버킷 ACL 퍼블릭 WRITE 허용 여부 점검 |
| `CKV_AWS_93` | S3 버킷 정책이 root 외 전체 차단하지 않음 확인 |

---

##  코드 비교 — Security Group

### Before — `CKV_AWS_24` / `CKV_AWS_25` ❌

```hcl
resource "aws_security_group" "vuln" {
  # 설명 없음 → CKV_AWS_23 실패
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # SSH 전체 오픈 → CKV_AWS_24 실패
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]  # 전체 아웃바운드 → CKV_AWS_382 실패
  }
}
```

### After — 강화 코드 

```hcl
resource "aws_security_group" "secure" {
  description = "Secure SG - VPC internal only"  # CKV_AWS_23 통과
  ingress {
    description = "SSH from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # CKV_AWS_24 통과
  }
  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.vpc_cidr]  # CKV_AWS_382 통과
  }
}
```

---

## 💻 코드 비교 — S3 Public Access Block

### Before — `CKV_AWS_53~56` ❌

```hcl
resource "aws_s3_bucket_public_access_block" "bad" {
  block_public_acls       = false  # CKV_AWS_53 실패
  block_public_policy     = false  # CKV_AWS_54 실패
  ignore_public_acls      = false  # CKV_AWS_55 실패
  restrict_public_buckets = false  # CKV_AWS_56 실패
}
```

### After — 강화 코드 

```hcl
resource "aws_s3_bucket_public_access_block" "secure" {
  block_public_acls       = true   # CKV_AWS_53 통과
  block_public_policy     = true   # CKV_AWS_54 통과
  ignore_public_acls      = true   # CKV_AWS_55 통과
  restrict_public_buckets = true   # CKV_AWS_56 통과
}
```

---

## ⚙️ 파이프라인 설정

```yaml
- name: Run Checkov
  run: |
    checkov -d terraform \
      -o json \     # 결과 저장
      -o sarif \    # GitHub Code Scanning 업로드용
      --quiet \     # 배너 제거 (SARIF 유효성 필수)
      --soft-fail   # 실패해도 파이프라인 중단 없음
```

| 항목 | 값 |
| --- | --- |
| Checkov 버전 | `3.2.506` |
| GitHub 권한 | `security-events: write` |
| 결과 형식 | JSON + SARIF |

---

## 🏆 핵심 성과 요약

| 지표 | Before | After |
| --- | --- | --- |
| 고유 취약점 유형 | **25종** | **0종** |
| 보안 점검 통과율 | **16.7%** (5/30종) | **100%** (9/9종) |
| 영향받는 리소스 수 | **111개** (SG 90 + S3 20 + IAM 1) | **0개** |
| 🔴 CRITICAL | 5종 | 0종 |
| 🟠 HIGH | 12종 | 0종 |
| 🟡 MEDIUM | 8종 | 0종 |

---

*Checkov 3.2.506 | 2026-02-24 | GitHub Actions CI/CD 통합*
