# Task 4 Report: Nessus Real-Scan + Prowler Launch-Scan Bridge + Demo Runbook

## 1) Scope Implemented

1. Nessus full API lifecycle integrated:
   - create scan
   - launch
   - poll status
   - export
   - poll export
   - download results
2. Prowler Launch Scan bridge hook implemented in local `workspaces/prowler-upstream` source:
   - optional trigger from scan creation to GitHub Pipeline 01 dispatch
3. End-to-end guides added:
   - Prowler OSS pipeline bridge setup
   - Vulnerable infra before/after demo flow

## 2) Files Added/Changed

### 2.1 Infra scanner bridge
- `iac/scripts/nessus_scan_bridge.py` (new)
- `iac/scripts/infra_bridge_report.py` (updated for Nessus auth variants)
- `.github/workflows/security-pipeline-infra-scanner-bridges.yml` (new input + real Nessus step)

### 2.2 Prowler launch-scan bridge (local source patch)
- `workspaces/prowler-upstream/api/src/backend/api/scan_bridge.py` (new)
- `workspaces/prowler-upstream/api/src/backend/api/v1/views.py` (hook call in `ScanViewSet.create`)

### 2.3 Guides/Docs
- `docs/PROWLER_OSS_PIPELINE_BRIDGE_GUIDE.md` (new)
- `docs/VULNERABLE_INFRA_BEFORE_AFTER_DEMO_GUIDE.md` (new)
- `reports/TASK2_SCANNER_INTEGRATION_REPORT.md` (updated)

## 3) Runtime Notes

1. Nessus real scan requires secrets and target host input.
2. Prowler scan-bridge code is in `workspaces/prowler-upstream` local source:
   - This requires `docker-compose-dev.yml` build path to run patched API.
   - Prebuilt `docker-compose.yml` images will not load local source patch.

## 4) Verification Performed

1. Python syntax checks passed:
   - `iac/scripts/nessus_scan_bridge.py`
   - `iac/scripts/infra_bridge_report.py`
   - `workspaces/prowler-upstream/api/src/backend/api/scan_bridge.py`
   - `workspaces/prowler-upstream/api/src/backend/api/v1/views.py`
2. Workflow dispatch test attempted:
   - Failed at remote with `Unexpected inputs ["run_nessus_real_scan"]` before push (expected).

## 5) Next Execution Steps

1. Push workflow/script changes.
2. Re-run Infra Scanner Bridges workflow with:
   - `run_nessus_real_scan=true`
   - `target_host=<target>`
3. Start Prowler in dev compose and set `DJANGO_SCAN_BRIDGE_*` envs.
4. Click Launch Scan in Prowler UI and verify Pipeline 01 dispatch.

