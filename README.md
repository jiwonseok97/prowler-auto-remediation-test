# Prowler Auto Remediation (AWS + Terraform + GitHub Actions)

This repository runs a 4-step security pipeline:

1. Scan baseline with Prowler (CIS 1.4 + ISMS-P check bundle)
2. Generate category remediation Terraform and category PRs
3. Apply merged generated remediation
4. Rescan and verify FAIL reduction

## Pipeline Workflows

- `Security Pipeline - 01 Scan Baseline`
- `Security Pipeline - 02 Generate Remediation PRs`
- `Security Pipeline - 03 Apply Merged Generated Terraform Remediation`
- `Security Pipeline - 04 Verify FAIL Reduction`

Only these four workflows are required for the end-to-end demo.

## End-to-End Flow

```text
01 Scan Baseline
  input: account (region is fixed to ap-northeast-2/Seoul)
  output artifact: scan-<run_id>
    - baseline.asff.json
    - baseline_cis*.json (raw)
    - baseline_isms_p*.json (raw)
    - normalized_findings.json
    - prioritized_findings.json
    - scan_manifest.json

02 Generate Remediation PRs
  input: scan_run_id (from step 01)
  process:
    - normalize + prioritize FAIL findings
    - build remediation plan (PATCH_EXISTING / IMPORT_AND_PATCH / CREATE_MISSING / SKIP)
    - generate Terraform by category
    - terraform fmt/validate gate
    - build manifest + import map
    - create PR per category branch
  output artifact: remediation-<run_id>

PR Merge (manual)
  branch strategy (fixed branches):
    - remediation/iam
    - remediation/s3
    - remediation/network-ec2-vpc
    - remediation/cloudtrail
    - remediation/cloudwatch

03 Apply Merged Generated Terraform Remediation
  trigger: push to main after PR merge
  process:
    - copy merged remediation scope
    - auto import existing resources by ARN/import id
    - resilient apply per category (partial failure tolerant)
  output artifact: apply logs and scope

04 Verify FAIL Reduction
  trigger: workflow_run success from step 03
  process:
    - wait
    - rerun Prowler on same account/region (Seoul, CIS + ISMS-P)
    - compare baseline FAIL vs post FAIL
  success condition:
    - post_fail < baseline_fail
```

## Current Code Layout

```text
.github/workflows/
  security-pipeline-01-scan-baseline.yml
  security-pipeline-02-generate-remediation-prs.yml
  security-pipeline-03-apply-merged-generated-terraform-remediation.yml
  security-pipeline-04-verify-fail-reduction.yml

iac/scripts/
  convert_findings.py
  osfp_score.py
  normalize_findings.py
  generate_remediation.py
  generate_remediation_bundle.py
  builder_to_manifest.py
  create_category_prs.py
  auto_import.sh
  resilient_apply.sh
  compare_failures.py
  validate_generated_tf.sh

iac/snippets/
  check_map.yaml
  iam/
  s3/
  cloudtrail/
  cloudwatch/
  network-ec2-vpc/

remediation/
  iam/
  s3/
  network-ec2-vpc/
  cloudtrail/
  cloudwatch/
```

## Local Workspace Layout

Local-only files are grouped to keep the repository root clean:

- `local/tmp/`: temporary files
- `local/workspaces/`: ad-hoc implementation workspaces
- `local/trust-policy.json`: local OIDC trust policy draft file

## Supported Auto-Remediation Scope

- IAM
- S3
- CloudTrail
- CloudWatch Logs / Metric Filters / Alarms
- EC2 Security Groups
- VPC Flow Logs

Unsupported checks are logged as `SKIPPED` (not hard error).

## Required GitHub Configuration

Repository Settings -> Actions -> General:

- Workflow permissions: `Read and write permissions`
- Enable `Allow GitHub Actions to create and approve pull requests`

## Required Secrets / Variables

Secrets:

- `AWS_OIDC_ROLE_ARN` (recommended)
- or static AWS credentials (legacy fallback)
- `PROWLER_APP_API_URL` (optional: baseline/rescan JSON publish endpoint)
- `PROWLER_APP_API_TOKEN` (optional: bearer token for publish endpoint)

Variables:

- `AWS_REGION` (optional for other tooling; pipeline is fixed to `ap-northeast-2`)

## ISMS-P Mapping

- ISMS-P additional scan target checks are defined in `iac/compliance/isms_p_checks.txt`.
- The pipeline runs `cis_1.4_aws` plus this check bundle and merges findings before normalization/remediation.

## Runbook

1. Run `Security Pipeline - 01 Scan Baseline`.
2. Run `Security Pipeline - 02 Generate Remediation PRs` with `scan_run_id` from step 1.
3. Review and merge category PRs (`remediation/<category>`).
4. Confirm step 3 apply workflow completed.
5. Confirm step 4 summary shows FAIL reduction.

## Notes

- Existing resources are imported and patched when possible.
- Optional Terraform sub-config resources may be created when import returns non-existent object.
- Apply is category-isolated; one category failure does not block others.
- If `PROWLER_APP_API_URL` and `PROWLER_APP_API_TOKEN` are configured, step 01 and step 04 publish JSON results to external API. If missing, publish steps are skipped.
