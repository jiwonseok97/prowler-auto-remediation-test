# Prowler OSS -> GitHub Pipeline Integration Guide (Step-by-Step)

## Goal
- Run Prowler OSS in dev compose.
- Trigger your GitHub Pipeline 01 automatically when a scan is created from Prowler.
- Keep AWS-provider-backed data visible in the Prowler dashboard.

## Repository layout
- Pipeline repo root: `c:\Users\ws567\prowler-auto\prowler-auto-remediation-test`
- Prowler app workspace: `c:\Users\ws567\prowler-auto\prowler-auto-remediation-test\workspaces\prowler-upstream`

## 1) Start Prowler dev compose
```powershell
cd c:\Users\ws567\prowler-auto\prowler-auto-remediation-test\workspaces\prowler-upstream
docker compose -f docker-compose-dev.yml up -d --build
docker compose -f docker-compose-dev.yml ps
```

Expected services up:
- `api-dev`
- `ui-dev`
- `worker-dev`
- `worker-beat`
- `postgres`
- `valkey`
- `neo4j`
- `mcp-server`

## 2) Configure scan bridge in `.env`
File: `workspaces/prowler-upstream/.env`

Set:
```env
DJANGO_SCAN_BRIDGE_ENABLED=true
DJANGO_SCAN_BRIDGE_MODE=github_dispatch
DJANGO_SCAN_BRIDGE_GH_REPO=jiwonseok97/prowler-auto-remediation-test
DJANGO_SCAN_BRIDGE_GH_WORKFLOW=scan-cis.yml
DJANGO_SCAN_BRIDGE_REF=main
DJANGO_SCAN_BRIDGE_ACCOUNT_ID_SOURCE=provider_uid
DJANGO_SCAN_BRIDGE_DEPLOY_VULNERABLE=true
DJANGO_SCAN_BRIDGE_COMPLIANCE_MODE=cis_1.4_plus_isms_p
DJANGO_SCAN_BRIDGE_TIMEOUT_SEC=20
DJANGO_SCAN_BRIDGE_TOKEN=<github token with workflow dispatch permission>
```

Then restart:
```powershell
docker compose -f docker-compose-dev.yml down
docker compose -f docker-compose-dev.yml up -d
```

## 3) Confirm default dev users and provider fixtures
Default dev credentials:
- `dev@prowler.com / Thisisapassword123@`
- `dev2@prowler.com / Thisisapassword123@`

Fixture-backed AWS provider exists in tenant for `dev@prowler.com`.

## 4) Real verification: create scan -> Pipeline 01 auto-trigger

### 4.1 Create token (JSON:API)
```powershell
$payload = '{"data":{"type":"tokens","attributes":{"email":"dev@prowler.com","password":"Thisisapassword123@"}}}'
$tok = (Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/v1/tokens -Headers @{ 'Content-Type'='application/vnd.api+json'; 'Accept'='application/vnd.api+json' } -Body $payload).data.attributes.access
```

### 4.2 Create scan (same action path as scan trigger)
```powershell
$scanPayload = '{"data":{"type":"scans","attributes":{"name":"bridge-auto-trigger-demo"},"relationships":{"provider":{"data":{"type":"providers","id":"15fce1fa-ecaa-433f-a9dc-62553f3a2555"}}}}}'
Invoke-RestMethod -Method Post -Uri http://localhost:8080/api/v1/scans -Headers @{ 'Content-Type'='application/vnd.api+json'; 'Accept'='application/vnd.api+json'; 'Authorization'="Bearer $tok" } -Body $scanPayload
```

### 4.3 Verify GitHub run starts automatically
```powershell
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow scan-cis.yml --limit 5
```

Observed verification run:
- Auto-triggered Pipeline 01 run: `22265238496`
- URL: `https://github.com/jiwonseok97/prowler-auto-remediation-test/actions/runs/22265238496`

## 5) End-to-end pipeline chain after trigger
- 01 Scan Baseline -> 02 Generate PRs -> merge PR -> 03 Apply -> 04 Verify FAIL reduction

Commands:
```powershell
# watch a run
gh run watch <run_id> --repo jiwonseok97/prowler-auto-remediation-test --exit-status

# open PRs from remediation generation
gh pr list --repo jiwonseok97/prowler-auto-remediation-test --state open

# merge remediation PR
gh pr merge <pr_number> --repo jiwonseok97/prowler-auto-remediation-test --squash --delete-branch
```

## 6) Known behavior
- Pipeline trigger from scan creation is verified.
- In one API test, local scan task itself returned `Scan.DoesNotExist` while dispatch still succeeded. This does not block GitHub workflow dispatch verification.

## 7) Dashboard data meaning
- Prowler dashboard shows findings/resources from scans inside Prowler app tenant/provider context.
- Your GitHub 01-04 pipeline is separate unless scan bridge is enabled.
- With bridge enabled, scan creation can trigger pipeline; dashboard still reflects provider scan data in app DB.

## 8) Security and operations
- Never commit real PAT/token in `.env`.
- Rotate token if exposed.
- Prefer short-lived GitHub tokens and scoped permissions.
