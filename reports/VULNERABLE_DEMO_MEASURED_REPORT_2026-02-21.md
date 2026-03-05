# Vulnerable Infra Demo Report (Before/After, Measured)

## Scope
This report documents an actual end-to-end demo run:
1. Deploy vulnerable infra and run baseline scan (Pipeline 01).
2. Generate remediation PR (Pipeline 02).
3. Merge PR and apply remediation (Pipeline 03).
4. Re-scan and measure FAIL reduction (Pipeline 04).

## Run ledger (actual)

| Stage | Workflow | Run ID | Result | URL |
|---|---|---:|---|---|
| 01 | Security Pipeline - 01 Scan Baseline (deploy_vulnerable=true) | 22265311726 | success | https://github.com/jiwonseok97/prowler-auto-remediation-test/actions/runs/22265311726 |
| 02 | Security Pipeline - 02 Generate Remediation PRs | 22265408997 | success | https://github.com/jiwonseok97/prowler-auto-remediation-test/actions/runs/22265408997 |
| PR | PR-merge / remediation: all-categories | #121 | merged | https://github.com/jiwonseok97/prowler-auto-remediation-test/pull/121 |
| 03 | Security Pipeline - 03 Apply Merged Generated Terraform Remediation | 22265590062 | success | https://github.com/jiwonseok97/prowler-auto-remediation-test/actions/runs/22265590062 |
| 04 | Security Pipeline - 04 Verify FAIL Reduction | 22265645493 | success | https://github.com/jiwonseok97/prowler-auto-remediation-test/actions/runs/22265645493 |

## Measured outcomes

### Baseline (after vulnerable deploy)
Source: `scan-22265311726/prioritized_findings.json`
- `baseline_fail = 137`

Top FAIL contributors:
- `prowler-s3_bucket_no_mfa_delete`: 64
- `prowler-s3_bucket_secure_transport_policy`: 40
- `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports`: 30
- `prowler-iam_root_hardware_mfa_enabled`: 1
- `prowler-ec2_ebs_volume_encryption`: 1
- `prowler-ec2_instance_profile_attached`: 1

### Post-apply rescan
Source: `rescan-22265645493/rescan_summary.json`
- `post_fail = 67`
- `reduced = 70` (baseline -> current)
- `actionable_fail(terraform-capable) = 0`
- `manual_fail(exception/manual) = 67`

Remaining FAIL IDs:
- `prowler-s3_bucket_no_mfa_delete` (64)
- `prowler-iam_root_hardware_mfa_enabled` (1)
- `prowler-ec2_ebs_volume_encryption` (1)
- `prowler-ec2_instance_profile_attached` (1)

## Interpretation
- The remediation pipeline removed all currently terraform-capable FAILs in this run.
- Remaining 67 are manual/exception-class controls, primarily MFA delete and account-level manual controls.

## Demo script (for presentation)

### A) Trigger vulnerable baseline
```powershell
gh workflow run "Security Pipeline - 01 Scan Baseline" --repo jiwonseok97/prowler-auto-remediation-test -f deploy_vulnerable=true -f account_id=132410971304 -f compliance_mode=cis_1.4_plus_isms_p
```

### B) Wait 01 and 02
```powershell
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 01 Scan Baseline" --limit 1
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 02 Generate Remediation PRs" --limit 1
```

### C) Merge generated PR
```powershell
gh pr list --repo jiwonseok97/prowler-auto-remediation-test --state open
gh pr merge <PR_NUMBER> --repo jiwonseok97/prowler-auto-remediation-test --squash --delete-branch
```

### D) Wait 03 and 04
```powershell
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 03 Apply Merged Generated Terraform Remediation" --limit 1
gh run list --repo jiwonseok97/prowler-auto-remediation-test --workflow "Security Pipeline - 04 Verify FAIL Reduction" --limit 1
```

### E) Show before/after artifact evidence
```powershell
gh run download <run01_id> --repo jiwonseok97/prowler-auto-remediation-test --name scan-<run01_id> --dir tmp/demo/scan
gh run download <run04_id> --repo jiwonseok97/prowler-auto-remediation-test --name rescan-<run04_id> --dir tmp/demo/rescan
```

## Restore strategy
If you need to return to a known-clean state after a vulnerable demo:
1. Keep your AWS runtime backup snapshot before demo (state + resource inventory scripts already added).
2. Re-apply known-good remediation manifest with Pipeline 03.
3. Re-run Pipeline 04 and verify `actionable_fail(terraform-capable)=0`.

## What is not auto-remediated by Terraform here
- MFA-delete on existing S3 buckets (`s3_bucket_no_mfa_delete`) at scale.
- Root hardware MFA controls.
- Some account/identity controls requiring manual runbook.
