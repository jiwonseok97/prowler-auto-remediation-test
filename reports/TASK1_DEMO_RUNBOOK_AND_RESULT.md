# Task 1 Report: Vulnerable Infra Demo and 01->04 Result

## 1) Objective
- Create a high-FAIL environment for a live demo.
- Run full pipeline (`01 -> 02 -> 03 -> 04`) in order.
- Show before/after numbers and control-level details.
- Restore environment back to pre-vulnerable state.

## 2) Demo Scenario Design
- Region: `ap-northeast-2`
- Vulnerable Terraform profile (`terraform/vulnerable_infra_test`):
  - `vuln_bucket_count=40`
  - `security_group_count=30`
  - `cloudwatch_log_group_count=20`

Expected effect:
- FAIL increases significantly on S3 and network controls.
- Auto/remediable subset decreases after merge/apply.
- Manual-runbook subset remains and is reported separately.

## 3) Execution Plan (Presenter Script)
1. Baseline snapshot (no vulnerable deploy)
2. Vulnerable deploy + baseline scan
3. Generate single remediation PR
4. Merge PR and apply
5. Verify FAIL reduction (with split view: auto/remediable vs manual)
6. Restore to pre-vulnerable state

## 4) Run Evidence

### 4.1 Pre-vulnerable baseline
- Run ID:
- `baseline_fail`:
- Top FAIL checks:

### 4.2 Post vulnerable deployment baseline
- Run ID:
- `baseline_fail`:
- Delta vs pre-vulnerable:
- Top FAIL checks:

### 4.3 Remediation generation (02)
- Run ID:
- PR mode: single PR
- Created PR:
- Included categories/checks:

### 4.4 Apply merged remediation (03)
- Run ID:
- Apply status:
- Notable apply logs:

### 4.5 Verify reduction (04)
- Run ID:
- `baseline_fail`:
- `post_fail`:
- `reduced`:
- `actionable_fail(terraform-capable)`:
- `manual_fail(exception/manual)`:

## 5) Detailed Check-Level Comparison

### 5.1 Before -> After table
| Check ID | Before Count | After Count | Delta | Class |
|---|---:|---:|---:|---|

### 5.2 Remaining FAIL (manual/runbook)
| Check ID | Count | Reason |
|---|---:|---|

## 6) Live Demo Talk Track (for audience)
- Why FAIL increased (intentional vulnerable resources)
- Why only certain FAILs dropped automatically
- Why manual-runbook items are separated
- Governance meaning of remaining FAILs

## 7) Restore and Verification
- Restore method:
- Restore command/log summary:
- Post-restore scan run ID:
- Confirmed returned to pre-vulnerable level:

## 8) Conclusion
- Demo success criteria met/not met:
- Constraints observed:
- Next optimization:
