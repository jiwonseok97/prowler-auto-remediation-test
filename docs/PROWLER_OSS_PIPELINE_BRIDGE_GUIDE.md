# Prowler OSS -> Pipeline Bridge Guide (End-to-End)

This guide sets up:
- Real infra scanner bridge (Nessus API lifecycle)
- Prowler OSS "Launch Scan" -> GitHub Pipeline 01 trigger
- Dashboard flow with your connected AWS provider data

## 1. Prerequisites

```powershell
docker --version
docker compose version
gh --version
aws --version
```

Required:
- GitHub repo access (`gh auth status` must be OK)
- AWS OIDC role secret already configured in repo (`AWS_OIDC_ROLE_ARN`)
- Prowler AWS provider already connectable (account UID like `123456789012`)

## 2. Infra Scanner: Nessus Real API Bridge

### 2.1 Set GitHub secrets

Use one auth style:

1) `NESSUS_API_KEY` (full `X-ApiKeys` header value or gateway token), or
2) `NESSUS_ACCESS_KEY` + `NESSUS_SECRET_KEY`

Also set:
- `NESSUS_URL` (example `https://nessus.example.com:8834`)

### 2.2 Run workflow

Workflow:
- `Security Pipeline - Infra Scanner Bridges (Nessus/Qualys/InsightVM/OpenVAS)`

Inputs:
- `run_nessus_real_scan = true`
- `target_host = <scan_target_ip_or_dns>`

Result artifacts:
- `artifacts/infra-scanners/nessus/nessus_scan_result.json`
- `artifacts/infra-scanners/nessus/nessus_summary.json`
- `artifacts/infra-scanners/nessus/nessus_summary.md`

What is now implemented for Nessus:
1. scan create
2. launch
3. poll status until completed
4. export
5. poll export
6. download result JSON

## 3. Prowler "Launch Scan" -> Pipeline 01 Integration

Implemented in:
- `workspaces/prowler-upstream/api/src/backend/api/scan_bridge.py`
- `workspaces/prowler-upstream/api/src/backend/api/v1/views.py`

Behavior:
- When a scan is created via Prowler UI (`Launch Scan`), API `ScanViewSet.create` now runs an optional bridge hook.
- Hook can dispatch GitHub workflow directly (`workflow_dispatch`) in `github_dispatch` mode.

### 3.1 Important runtime note

`docker-compose.yml` uses prebuilt images, so source patches are not loaded there.

To run patched bridge logic, start Prowler with dev compose:

```powershell
cd C:\Users\ws567\prowler-auto\prowler-auto-remediation-test\workspaces\prowler-upstream
docker compose -f docker-compose-dev.yml up -d --build
```

### 3.2 Add bridge env vars in `workspaces/prowler-upstream/.env`

```dotenv
DJANGO_SCAN_BRIDGE_ENABLED=true
DJANGO_SCAN_BRIDGE_MODE=github_dispatch
DJANGO_SCAN_BRIDGE_GH_REPO=jiwonseok97/prowler-auto-remediation-test
DJANGO_SCAN_BRIDGE_GH_WORKFLOW=scan-cis.yml
DJANGO_SCAN_BRIDGE_REF=main
DJANGO_SCAN_BRIDGE_TOKEN=<github_pat_with_actions_write_repo_scope>
DJANGO_SCAN_BRIDGE_ACCOUNT_ID_SOURCE=provider_uid
DJANGO_SCAN_BRIDGE_DEPLOY_VULNERABLE=false
DJANGO_SCAN_BRIDGE_COMPLIANCE_MODE=cis_1.4_plus_isms_p
DJANGO_SCAN_BRIDGE_TIMEOUT_SEC=20
```

Then restart:

```powershell
docker compose -f docker-compose-dev.yml down
docker compose -f docker-compose-dev.yml up -d --build
```

### 3.3 Verify trigger path

1. Open Prowler UI
2. Launch scan with connected AWS provider
3. Check GitHub runs:

```powershell
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 01 Scan Baseline" --limit 5
```

Expected:
- New run appears shortly after scan creation.

## 4. Dashboard Data Clarification

Prowler dashboard data comes from:
- The AWS provider account connected in Prowler (`Configuration -> Cloud Providers`)
- Prowler backend scan results stored in its DB

This integration does not replace dashboard data source.
It adds an automation side effect: launch scan -> trigger your pipeline.

## 5. Quick Validation Checklist

1. Prowler UI launch scan works.
2. GitHub Pipeline 01 auto-dispatch occurs.
3. Pipeline artifacts publish to your external API (if configured).
4. Prowler dashboard still shows your connected AWS account findings.

