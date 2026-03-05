# Execution Trace (2026-02-21)

## Objective
- Validate `Prowler scan -> Pipeline 01` auto trigger in dev compose.
- Execute vulnerable-infra demo chain `01 -> 02 -> merge -> 03 -> 04` and collect measured outcomes.

## 1) Environment bring-up
- Verified docker dev stack up:
  - `api-dev`, `ui-dev`, `worker-dev`, `worker-beat`, `postgres`, `valkey`, `neo4j`, `mcp-server`.
- Confirmed scan bridge env variables in `workspaces/prowler-upstream/.env`.

## 2) Prowler scan to pipeline auto-trigger verification

### 2.1 Token + provider validation
- Logged in via JSON:API token endpoint with `dev@prowler.com`.
- Confirmed AWS provider exists (`id=15fce1fa-ecaa-433f-a9dc-62553f3a2555`).

### 2.2 Scan create API call
- POST `/api/v1/scans` with provider relationship.
- Observed immediate GitHub run creation:
  - `scan-cis.yml` new run `22265238496` (in_progress then success).

Result:
- Auto dispatch from scan path is confirmed.

## 3) Vulnerable infra demo full chain

### 3.1 Run 01 with vulnerable deploy enabled
- Triggered: `22265311726`
- Input: `deploy_vulnerable=true`, `account_id=132410971304`, `compliance_mode=cis_1.4_plus_isms_p`
- Conclusion: success.

### 3.2 Auto run 02
- Triggered by workflow_run: `22265408997`
- Conclusion: success.
- Output: single remediation PR generated.

### 3.3 Merge remediation PR
- Merged PR: `#121` (`PR-merge / remediation: all-categories`)
- Merge commit: `723a93326a545a27cdf680bba180796f5e692e01`

### 3.4 Auto run 03 (apply)
- Triggered by push: `22265590062`
- Conclusion: success.

### 3.5 Auto run 04 (verify)
- Triggered by workflow_run: `22265645493`
- Conclusion: success.

## 4) Measured numbers extracted from artifacts
- Baseline FAIL (run 01 artifact): `137`
- Post FAIL (run 04 artifact): `67`
- Reduced: `70`
- Terraform-capable remaining FAIL: `0`
- Manual-runbook remaining FAIL: `67`

## 5) Notes
- Some workflow logs include `Process completed with exit code 2` annotation while run conclusion remains `success`; this is a known behavior in the current pipeline and did not block chain completion.
- All requested chain stages were completed and measured in this execution set.
