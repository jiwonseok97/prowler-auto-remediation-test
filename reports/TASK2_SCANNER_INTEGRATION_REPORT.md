# Task 2 Report: IaC/Infra Scanner Integration

## 1) Objective
- Integrate requested scanner set into this repository structure.
- Split outcomes into:
  - usable now
  - usable with secrets/licenses
  - later (external platform dependency)

## 2) What Was Implemented

### 2.1 New workflows
- `.github/workflows/security-pipeline-iac-scanners.yml`
  - Checkov
  - tfsec
  - Terrascan
  - Snyk IaC (optional via `SNYK_TOKEN`)
- `.github/workflows/security-pipeline-infra-scanner-bridges.yml`
  - Nessus bridge readiness
  - Qualys bridge readiness
  - InsightVM bridge readiness
  - OpenVAS bridge readiness
  - Optional endpoint connectivity check (HTTP status test when URL secrets exist)

### 2.2 New script
- `iac/scripts/infra_bridge_report.py`
  - Generates:
    - `bridge-readiness.json`
    - `summary.md`
    - `ready-urls.json` (for optional endpoint HTTP checks)

### 2.2 Execution runs
- IaC scanner run: `22264147855` (success)
- Infra bridge run: `22264147880` (success)

## 3) Tool Matrix (Now vs Later)

### 3.1 IaC scanning (target 4)
| Tool | Current Status | Execution Result | Blocking Requirement | Benefit |
|---|---|---|---|---|
| Checkov | now | `checkov-terraform failed=690, passed=181` / `checkov-remediation failed=0, passed=80` | none | strong policy coverage for Terraform misconfigurations |
| tfsec | now | `tfsec-terraform failed=490` / `tfsec-remediation failed=0` | none | fast static feedback in PR/workflow |
| Terrascan | now (tuned) | violations detected (`terraform scan_summary.violated_policies=2`) | optional scanner tuning by IaC type | policy-as-code perspective complementing Checkov/tfsec |
| Snyk IaC | partial-now | skipped in run (`missing SNYK_TOKEN`) | `SNYK_TOKEN` | commercial rule feed, governance/reporting integration |

### 3.2 Infra scanning (target 4)
| Tool | Current Status | Execution Result | Blocking Requirement | Benefit |
|---|---|---|---|---|
| Nessus | later-ready bridge | readiness reported as `later` | `NESSUS_URL`, `NESSUS_API_KEY` | vuln assessment at host/service layer |
| Qualys | later-ready bridge | readiness reported as `later` | `QUALYS_API_URL`, `QUALYS_USERNAME`, `QUALYS_PASSWORD` | enterprise VM management integration |
| InsightVM | later-ready bridge | readiness reported as `later` | `INSIGHTVM_URL`, `INSIGHTVM_API_KEY` | risk-prioritized asset-level vulnerability data |
| OpenVAS | later-ready bridge | readiness reported as `later` | `OPENVAS_URL`, `OPENVAS_USERNAME`, `OPENVAS_PASSWORD` | open-source infra scanner option |

Note:
- If required URL/API secrets are configured, workflow now performs endpoint connectivity tests and publishes HTTP status table in the run summary.

## 4) Artifact Evidence
- IaC artifacts:
  - `checkov-terraform.json`
  - `checkov-remediation.json`
  - `tfsec-terraform.json`
  - `tfsec-remediation.json`
  - `terrascan-terraform.json`
  - `terrascan-remediation.json`
  - `snyk-iac.json`
  - `summary.md`
- Infra bridge artifacts:
  - `bridge-readiness.json`
  - `summary.md`

## 5) Practical Benefits for Current Pipeline
- Shift-left gain:
  - Detect IaC risk before 01/02/03/04 cloud execution.
- Cross-validation gain:
  - Static IaC findings + runtime Prowler findings improve confidence.
- Remediation quality gain:
  - `remediation/` output can be scanned directly (`failed=0` in this run for checkov/tfsec).
- Governance gain:
  - Infra scanner bridges document exact prerequisite gaps instead of ad-hoc setup.

## 6) Remaining Work (Later)
1. Set scanner secrets for Nessus/Qualys/InsightVM/OpenVAS bridge activation.
2. Add API job steps per vendor (scan launch, polling, result ingest).
3. Normalize external scanner findings into common report schema (with severity mapping).
4. Add gating policy (advisory vs blocking threshold) per environment.
