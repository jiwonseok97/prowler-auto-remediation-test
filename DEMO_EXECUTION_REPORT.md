# Security Demo Execution Report

## Goal
- Create a high-FAIL scenario that is largely recoverable in one remediation cycle.
- Keep non-terraform/manual-only noise lower during demo runs.

## Step 1 Configuration Applied (High FAIL, One-Shot Friendly)
- `scan-cis.yml`: `deploy_vulnerable` default is `true`.
- `remediate-pr.yml`:
  - `single_pr_mode` default is now `true`.
  - `workflow_run` auto-trigger now also uses `single_pr_mode=true`.
- `terraform/vulnerable_infra_test` defaults tuned for demo:
  - `vuln_bucket_count=0`
  - `security_group_count=0`
  - `cloudwatch_log_group_count=60`

Reason:
- Large S3 bucket creation tends to inflate manual-runbook checks (for example MFA-delete) that are not terraform-remediable.
- Unencrypted CloudWatch log groups are better for "raise FAIL -> auto-remediate -> visible drop" flow.

## Expected Demo Effect
- Baseline FAIL increases significantly when vulnerable infra is deployed.
- Workflow 02 creates one consolidated remediation PR.
- After merge/apply (03) and verify (04), terraform-capable FAIL should drop in one cycle.

## Execution Notes
- If apply succeeds but no FAIL reduction occurs, workflow 04 treats it as neutral warning (not hard failure).
- Incremental reduction is measured against previous successful rescan.

---

## Bottom Classification (Now vs Later)

### A) Can Continue Now (Pipeline-Auto/Review)
- Terraform-capable FAIL:
  - cloudwatch/cloudtrail/s3/iam/network checks already mapped in `iac/snippets/check_map.yaml`
  - checks with generated actionable plans (`PATCH_EXISTING`, `IMPORT_AND_PATCH`, `CREATE_MISSING`)
- Recommended operation:
  - Run `01 -> 02(single PR) -> merge -> 03 -> 04`
  - Repeat while terraform-capable FAIL remains

### B) Should Be Planned Later (Manual/Exception)
- Manual-runbook FAIL:
  - policy/organizational/account-level controls that cannot be safely auto-remediated in Terraform-only flow
  - controls requiring privileged human validation, exception handling, or process changes
- Recommended operation:
  - Manage via manual runbook, approvals, and security governance tasks
  - Track separately from auto-remediation reduction KPI
