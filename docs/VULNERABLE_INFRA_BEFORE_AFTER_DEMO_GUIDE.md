# Vulnerable Infra Before/After Demo Guide

Goal:
- Intentionally increase FAIL count using test infra
- Run pipeline 01->04
- Show large before/after reduction
- Restore environment back to pre-demo state

## 1. Demo Scope

Vulnerable test Terraform path:
- `terraform/vulnerable_infra_test`

Injected risk examples:
- public S3 bucket access block disabled
- public-open security groups
- unencrypted CloudWatch log groups

## 2. Pre-Demo Safety (Backup)

Run runtime backup first:

```powershell
cd C:\Users\ws567\prowler-auto\prowler-auto-remediation-test
powershell -ExecutionPolicy Bypass -File iac/scripts/backup_aws_runtime_state.ps1
```

Keep backup path output. You can restore later with:

```powershell
powershell -ExecutionPolicy Bypass -File iac/scripts/restore_aws_runtime_state.ps1 -BackupDir <backup_dir_path>
```

## 3. Deploy Vulnerable Test Infra

```powershell
cd C:\Users\ws567\prowler-auto\prowler-auto-remediation-test
terraform -chdir=terraform/vulnerable_infra_test init -input=false
terraform -chdir=terraform/vulnerable_infra_test apply -auto-approve -input=false
```

## 4. Run Pipeline Sequence

## 4.1 Run baseline scan (01)

```powershell
gh workflow run "Security Pipeline - 01 Scan Baseline" `
  --repo jiwonseok97/prowler-auto-remediation-test `
  -f deploy_vulnerable=false `
  -f account_id=132410971304 `
  -f compliance_mode=cis_1.4_plus_isms_p
```

Monitor:

```powershell
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 01 Scan Baseline" --limit 3
```

## 4.2 Generate remediation PRs (02)

```powershell
gh workflow run "Security Pipeline - 02 Generate Remediation PRs" --repo jiwonseok97/prowler-auto-remediation-test
```

Check PRs:

```powershell
gh pr list --repo jiwonseok97/prowler-auto-remediation-test --state open
```

Merge remediation PRs in your chosen order.

## 4.3 Apply merged remediation (03)

Pipeline 03 should run from merged-PR trigger.
If needed, run manually from Actions UI.

## 4.4 Verify reduction (04)

Pipeline 04 runs after 03 success.
Check summary:
- baseline_fail
- post_fail
- reduced
- actionable(terraform-capable) vs manual(exception/manual)

## 5. Demo Script (Audience-Friendly)

Use this speaking flow:
1. "Current baseline FAIL is X"
2. "Deploy intentionally vulnerable infra"
3. "Re-scan and show FAIL increased to Y"
4. "Run remediation PR generation and apply"
5. "Show post_fail reduced to Z"
6. "Show remaining are manual/exception class"

## 6. Restore to Pre-Demo State

Option A (exact runtime restore snapshot):

```powershell
powershell -ExecutionPolicy Bypass -File iac/scripts/restore_aws_runtime_state.ps1 -BackupDir <backup_dir_path>
```

Option B (remove only vulnerable test stack):

```powershell
terraform -chdir=terraform/vulnerable_infra_test destroy -auto-approve -input=false
```

Option A is preferred when you need the strongest rollback guarantee.

## 7. Evidence Collection for Report

Collect:
1. 01 summary (`baseline_fail`, fail-by-check table)
2. 02 generated PR list
3. 03 apply result log
4. 04 rescan summary (`reduced`, remaining tables)

Recommended output location:
- `reports/` as dated markdown report

