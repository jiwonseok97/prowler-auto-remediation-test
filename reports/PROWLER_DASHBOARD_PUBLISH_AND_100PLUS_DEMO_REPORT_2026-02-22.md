# Prowler Dashboard Publish + >100 Demo Measured Report (2026-02-22)

## Scope

This report documents two completed items:

1. GitHub pipeline results (`01` / `04`) published back to the local Prowler App and exposed for dashboard UI usage.
2. A >100 vulnerability demo run (injected auto-remediable scope) executed through `01 -> 02 -> PR merge -> 03 -> 04` with measured before/after counts.

## A. Pipeline -> Prowler App Publish Integration (Verified)

### What was implemented

- Prowler API endpoint (local dev app):
  - `POST /api/v1/pipeline-publish/events`
  - `GET /api/v1/pipeline-publish/latest`
- UI proxy route under app domain (so GitHub can publish to the same tunnel domain):
  - `/api/v1/pipeline-publish/events`
  - `/api/v1/pipeline-publish/latest`
- Overview page badge (top-right area) to display latest pipeline upload timestamp / event / run id.
- `iac/scripts/publish_scan_to_api.py` remote update to normalize base URL secrets into the full endpoint path automatically.

### Publish endpoint verification (through current quick tunnel)

Tunnel domain used:
- `https://communities-graph-students-claims.trycloudflare.com`

Verified:
- `GET /api/v1/pipeline-publish/latest` returns `200`
- `POST /api/v1/pipeline-publish/events` returns `200`
- latest state persisted and retrievable

### GitHub workflow publish verification (actual runs)

#### Baseline publish (`01`)
- Workflow: `Security Pipeline - 01 Scan Baseline`
- Run ID: `22274498597`
- Result: `success`
- Publish log evidence:
  - `published event=baseline_scan status=200 url=***/api/v1/pipeline-publish/events`

#### Rescan publish (`04`)
- Workflow: `Security Pipeline - 04 Verify FAIL Reduction`
- Run ID: `22274878452`
- Result: `success`
- Publish log evidence:
  - `published event=rescan_verify status=200 url=***/api/v1/pipeline-publish/events`

### Latest published payload currently visible to UI (endpoint response)

Latest upload at verification time:
- `received_at`: `2026-02-22T10:04:25.112236+00:00`
- `event`: `rescan_verify`
- `run_id`: `22274878452`
- `summary.baseline_fail`: `251`
- `summary.post_fail`: `155`
- `summary.reduced`: `96`

Note:
- This latest value is what the overview badge should show (top-right area) after refreshing the Prowler Overview page.

## B. >100 Demo (Auto-Remediable Scope) Measured Results

This section is the presentation/demo-friendly measurement for the >100 injected vulnerability scenario.

### Demo chain (actual executed runs)

1. `01 Scan Baseline` (demo vulnerable infra deployed): `22273442824`
2. `02 Generate Remediation PRs`: `22273546350`
3. Merge PR: `#124` (`PR-merge / remediation: all-categories`)
4. `03 Apply Merged Generated Terraform Remediation`: `22273864723`
5. `04 Verify FAIL Reduction`: `22273921530`

Artifacts used:
- Baseline artifact from `01` (`scan-22273442824`)
- Rescan artifact from `04` (`rescan-22273921530`)

### 1) All FAIL (Account-wide) before/after

| Metric | Count |
|---|---:|
| Baseline FAIL | 251 |
| Post-apply FAIL | 135 |
| Reduced | 116 |

Interpretation:
- Account-wide FAIL includes accumulated manual/noise items (especially S3 MFA Delete on service log buckets), so this is not the cleanest demo metric for automation effect.

### 2) Demo-effective FAIL (auto-remediable / non-manual focus)

This excludes manual-runbook-heavy items from the demonstration effect calculation.

| Metric | Count |
|---|---:|
| Baseline (demo-effective) | 118 |
| Post-apply (demo-effective) | 2 |
| Reduced | 116 |

### 3) Injected-check-only FAIL (pure demo injection score)

Injected checks intentionally used for the demo:
- `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports`
- `prowler-s3_bucket_secure_transport_policy`
- IAM password policy checks (6)

| Metric | Count |
|---|---:|
| Baseline (injected only) | 116 |
| Post-apply (injected only) | 0 |
| Reduced | 116 |

Interpretation:
- All intentionally injected demo vulnerabilities were remediated by the pipeline (`116 -> 0`).

## C. Demo Vulnerability Composition (Category Diversity)

### Baseline injected/auto-remediable composition

| Category | Count |
|---|---:|
| Network / EC2 / VPC | 90 |
| S3 | 20 |
| IAM | 6 |
| Total | 116 |

### Detailed checks used in the demo

| Check ID | Count | Category |
|---|---:|---|
| `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports` | 90 | Network |
| `prowler-s3_bucket_secure_transport_policy` | 20 | S3 |
| `prowler-iam_password_policy_minimum_length_14` | 1 | IAM |
| `prowler-iam_password_policy_reuse_24` | 1 | IAM |
| `prowler-iam_password_policy_lowercase` | 1 | IAM |
| `prowler-iam_password_policy_number` | 1 | IAM |
| `prowler-iam_password_policy_symbol` | 1 | IAM |
| `prowler-iam_password_policy_uppercase` | 1 | IAM |

## D. Why All FAIL Does Not Drop to the Demo Floor

The remaining account-wide FAIL after the demo run is dominated by manual/non-terraform items, especially:
- `prowler-s3_bucket_no_mfa_delete` (service log buckets such as CloudTrail/Config)
- `prowler-iam_root_hardware_mfa_enabled`
- a small number of EC2 items requiring review/manual action

This is expected and does not invalidate the automation demo.

For demos, present both:
- **All FAIL** (account reality)
- **Injected-check-only / demo-effective FAIL** (automation impact)

## E. Presenter Notes (Recommended Narrative)

1. Launch a scan from Prowler App (or trigger `01`) and show GitHub pipeline `01` starts.
2. Show baseline is high because intentionally vulnerable infra is deployed.
3. Show `02` generates `all-categories` remediation PR.
4. Merge the PR and show `03 -> 04` complete automatically.
5. Present the **injected-check-only** metric (`116 -> 0`) as the clean automation success score.
6. Explain why account-wide FAIL remains higher (manual/noise categories).

## F. References

- Prowler->pipeline publish baseline verify run: `22274498597`
- Prowler->pipeline publish rescan verify run: `22274878452`
- >100 demo `01`: `22273442824`
- >100 demo `02`: `22273546350`
- >100 demo PR: `#124`
- >100 demo `03`: `22273864723`
- >100 demo `04`: `22273921530`
