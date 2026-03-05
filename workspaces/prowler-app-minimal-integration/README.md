# Prowler App Minimal Integration Workspace

## Original Prowler UI/API (same product UI)

Upstream source is cloned at:
- `../prowler-upstream`

Run the original Prowler App stack (UI + API + DB + cache) with Docker:
```powershell
cd workspaces/prowler-app-minimal-integration
.\start-prowler-upstream.ps1
```

Check status:
```powershell
.\status-prowler-upstream.ps1
```

Stop:
```powershell
.\stop-prowler-upstream.ps1
```

Endpoints:
- UI: `http://localhost:3000`
- API docs: `http://localhost:8080/api/v1/docs`

Prerequisite:
- Docker Desktop must be running before start script.

---

Minimal app for:
- ingesting pipeline payloads from `Security Pipeline - 01/04`
- storing events in file-based storage (no DB)
- rendering dashboard (charts/list/filter)

## Implemented
- API ingest:
  - `POST /api/v1/prowler/results`
  - `POST /` (root fallback)
- API query:
  - `GET /api/v1/summary`
  - `GET /api/v1/events`
  - `DELETE /api/v1/events` (token required if configured)
- UI:
  - `GET /` dashboard
  - charts: event type + fail trend
  - table list + filters (account/region/framework)
- Storage:
  - `data/events.jsonl` append-only event log

## Run
```powershell
cd workspaces/prowler-app-minimal-integration
python -m venv .venv
. .venv/Scripts/Activate.ps1
pip install -r requirements.txt
$env:APP_API_TOKEN="gJ7mQ2vN8xR4pL9tK3sD6fH1wB5zC0yA"
uvicorn app:app --host 0.0.0.0 --port 8080
```

## Connect Pipeline
Set repo secrets:
- `PROWLER_APP_API_URL`: tunnel URL (`https://...trycloudflare.com`) or explicit endpoint (`https://.../api/v1/prowler/results`)
- `PROWLER_APP_API_TOKEN`: same value as `APP_API_TOKEN`

Pipeline publish is optional and non-blocking.

## Launch Scan Button (Optional)
To trigger GitHub workflow `01` from dashboard:
- set env `GH_TOKEN` (GitHub token with Actions: write on target repo)
- set env `GH_REPO` (e.g. `owner/repo`)
- optional `GH_SCAN_WORKFLOW` (default `scan-cis.yml`)
- optional `GH_REF` (default `main`)

Example:
```powershell
$env:GH_TOKEN="<github_pat_or_token>"
$env:GH_REPO="jiwonseok97/prowler-auto-remediation-test"
$env:GH_SCAN_WORKFLOW="scan-cis.yml"
$env:GH_REF="main"
```
