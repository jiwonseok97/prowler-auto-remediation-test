# Prowler Auto Remediation

Prowler 스캔 결과를 기준으로 IaC(Terraform) 보안 수정안을 생성하고,
PR/적용/재스캔까지 자동화하는 DevSecOps 파이프라인입니다.

## 핵심 흐름

1. **Prowler 스캔** (CIS 1.4 + ISMS-P) → 결과 정규화
2. **Remediation PR 생성** → 카테고리별 Terraform 수정안
3. **Merge 후 Apply** → 리소스 반영
4. **Rescan & 검증** → FAIL 감소 확인
5. **IaC 정적 분석** (Checkov) → SARIF 업로드

## 로컬 실행

### 1) Prowler Upstream 전체 스택
Docker로 API/UI/MCP 포함 전체 구동:

```powershell
cd workspaces/prowler-app-minimal-integration
.\start-prowler-upstream.ps1
```

기본 포트:
- UI: `http://localhost:3000`
- API: `http://localhost:8080/api/v1/docs`
- MCP: `http://localhost:8000/health`

중지:
```powershell
.\stop-prowler-upstream.ps1
```

### 2) Rescan Insights API
Rescan 인사이트 API 별도 실행:

```powershell
cd workspaces/prowler-app-minimal-integration
.\.venv\Scripts\python.exe -m uvicorn app:app --host 0.0.0.0 --port 8081
```

Endpoint:
- `http://localhost:8081/api/v1/rescan-insights`

### 3) UI 개발 서버
```powershell
cd workspaces/prowler-upstream/ui
npx pnpm exec next dev --webpack
```

필수 환경 변수 (`workspaces/prowler-upstream/ui/.env.local`):
```
NEXT_PUBLIC_API_BASE_URL=http://localhost:8080/api/v1
PROWLER_MCP_SERVER_URL=http://localhost:8000
RESCAN_INSIGHTS_API_URL=http://localhost:8081/api/v1/rescan-insights
```

## 주요 워크플로우

- `scan-cis.yml`: Prowler CIS 1.4 + ISMS-P 스캔
- `remediate-pr.yml`: FAIL 항목 기반 Terraform 수정 PR 생성
- `apply-on-merge.yml`: 머지된 remediation 적용
- `rescan-after-apply.yml`: 재스캔 및 개선 여부 확인
- `security-pipeline-iac-scanners.yml`: Checkov IaC 스캔 (SARIF)
- `security-pipeline-infra-scanner-bridges.yml`: OpenVAS 브릿지

## 주요 디렉터리

```
prowler-auto-remediation-test/
  .github/workflows/                 # GitHub Actions 파이프라인
  iac/scripts/                       # 스캔/정규화/PR 생성 스크립트
  terraform/vulnerable_infra_test/   # 취약 인프라 샘플
  remediation/                       # 자동 생성된 remediation 코드
  reports/                           # 결과 리포트(SARIF/JSON/HTML)
  workspaces/
    prowler-upstream/                # Prowler UI/API/MCP 소스
    prowler-app-minimal-integration/ # 로컬 실행 스크립트
```

## 참고

- UI: `http://localhost:3000`
- API: `http://localhost:8080`
- MCP Health: `http://localhost:8000/health`
- Rescan Insights: `http://localhost:8081/api/v1/rescan-insights`

```
작성 시점 기준: 2026-03-01
```
