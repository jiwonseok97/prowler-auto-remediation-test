# Cloud Security Auto-Remediation Pipeline (GitHub Actions + Terraform + AWS Prowler)

## A) Architecture / Flow

```text
[scan-cis.yml]
  input: account_id, region, deploy_vulnerable
  output artifacts: baseline.asff.json, normalized_findings.json, prioritized_findings.json, scan_manifest.json
        |
        v
[remediate-pr.yml]
  input: scan_run_id + account/region + model_id
  process: OSFP-prioritized FAIL -> template/Bedrock tf generation -> fmt/validate -> category manifest
  output artifacts/files: remediation/<category>/fix-<check_id>.tf, remediation/manifest.json
        |
        v
[PR per category]
  branch: remediation/<category>-<account>-<runid>
  trigger: human merge only
        |
        v
[apply-on-merge.yml]
  trigger: push to main by merged PR
  process: terraform init/plan/apply per category
  output artifacts: artifacts/apply/apply.log
        |
        v
[rescan-after-apply.yml]
  trigger: apply workflow success
  process: prowler rescan -> normalize -> baseline diff
  output artifacts: rescan_summary.json + summary.md (FAIL 감소/잔여 FAIL)
```

## B) Directory Structure

```text
.
├─ .github/workflows/
│  ├─ scan-cis.yml
│  ├─ remediate-pr.yml
│  ├─ apply-on-merge.yml
│  └─ rescan-after-apply.yml
├─ iac/scripts/
│  ├─ normalize_findings.py
│  ├─ osfp_score.py
│  ├─ write_scan_manifest.py
│  ├─ generate_remediation_bundle.py
│  ├─ validate_generated_tf.sh
│  ├─ build_category_manifest.py
│  ├─ create_category_prs.py
│  ├─ apply_merged_remediation.sh
│  └─ compare_failures.py
├─ iac/snippets/
│  ├─ check_map.yaml
│  ├─ iam/fix-iam_password_policy_strong.tf
│  ├─ s3/fix-s3_bucket_public_access_block.tf
│  ├─ s3/fix-s3_bucket_default_encryption.tf
│  ├─ cloudtrail/fix-cloudtrail_log_file_validation_enabled.tf
│  └─ cloudwatch/fix-cloudwatch_log_group_encrypted.tf
├─ remediation/
│  └─ <category>/fix-<check_id>.tf
├─ iam/bedrock-minimum-policy.json
└─ README.md
```

## C) OSFP Rule

Score (0-100):

`0.35*severity + 0.25*exploitability + 0.20*blast_radius + 0.15*compliance_impact + 0.05*(100-remediation_complexity)`

Priority Bucket:
- P0: >= 85
- P1: >= 70
- P2: >= 50
- P3: < 50

Example 1 (S3 public bucket): severity=80 exploit=90 blast=85 compliance=80 complexity=20 -> 82.75 (P1)
Example 2 (IAM weak password policy): severity=80 exploit=50 blast=85 compliance=80 complexity=60 -> 72.25 (P1)
Example 3 (CloudWatch encryption missing): severity=60 exploit=40 blast=55 compliance=80 complexity=40 -> 58.75 (P2)

## D) Environment / Secrets / Vars

Required GitHub Secrets:
- `AWS_OIDC_ROLE_ARN` (OIDC AssumeRole target)

Required workflow inputs:
- `account_id`
- `region`
- `scan_run_id` (for remediation workflow)
- `model_id` (Bedrock model)

Recommended Repository Variables:
- `AWS_REGION`

## E) Test / Validation Scenarios

1. Scan only
- Run `scan-cis.yml`
- Expect: scan artifacts uploaded, baseline_fail_count > 0

2. Remediation generation
- Run `remediate-pr.yml` with valid scan run id
- Expect: category tf files generated + terraform fmt/validate pass + category PRs created

3. Stale PR close
- Re-run remediation for same account/category
- Expect: previous open PR branch `remediation/<category>-<account>-*` auto closed

4. Apply on merge
- Merge one category PR
- Expect: `apply-on-merge.yml` runs, category terraform applied, apply log artifact uploaded

5. Rescan compare
- After apply workflow success
- Expect: `rescan-after-apply.yml` runs, summary includes `baseline_fail`, `post_fail`, `reduced`

## F) Top 10 Operational Failures + Fix

1. OIDC role assumption denied
- Fix: trust policy must include GitHub `sub`/`aud` claims

2. Bedrock InvokeModel AccessDenied
- Fix: attach `iam/bedrock-minimum-policy.json` actions/resource

3. Prowler scan produces no json
- Fix: keep fallback `[]` and validate AWS credentials + region

4. Malformed HCL from model
- Fix: strict prompt + `validate_generated_tf.sh` gate + fallback manual_required

5. Terraform validate fails provider init
- Fix: `_validate_provider.tf` temporary provider injection

6. Duplicate resource conflicts
- Fix: `fix-<check_id>.tf` naming + per-category isolation

7. Plan shows destructive changes
- Fix: enforce minimal-change snippets + lifecycle ignore where needed

8. Apply blocked by missing IAM perms
- Fix: extend role policy for exact service APIs only

9. Rescan baseline mismatch
- Fix: source baseline from `remediation/manifest.json` baseline_fail_count

10. PR creation fails due token scope
- Fix: workflow `permissions: contents:write, pull-requests:write`

## Runbook

1. Run `scan-cis.yml` with account_id/region.
2. Capture scan run id.
3. Run `remediate-pr.yml` with `scan_run_id`.
4. Review category PRs and merge selected PRs manually.
5. `apply-on-merge.yml` executes automatically on merged commits.
6. `rescan-after-apply.yml` runs and publishes FAIL diff summary.

## Assumptions

- Vulnerable infra already modeled in `terraform/test_infra`.
- Generated remediation is category-scoped (`iam`, `s3`, `cloudtrail`, `cloudwatch`).
- Non-terraform and manual-required checks are tracked but not auto-applied.
- Terraform backend is local for CI dry-run simplicity.