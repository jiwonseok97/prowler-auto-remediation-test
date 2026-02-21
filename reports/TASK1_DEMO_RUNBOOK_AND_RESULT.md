# Task 1 Report: Vulnerable Infra Demo and 01->04 Result

## 1) Objective
- Create a high-FAIL environment for live demo.
- Execute pipeline in strict order: 01 -> 02 -> PR merge -> 03 -> 04.
- Verify reduction and restore environment.

## 2) Demo Scenario (deployed)
- Region: `ap-northeast-2`
- Vulnerable Terraform profile:
  - `vuln_bucket_count=40`
  - `security_group_count=30`
  - `cloudwatch_log_group_count=20`

## 3) Execution Runs
1. Pre baseline (no vulnerable deploy): `01` run `22263429441`
2. Vulnerable deploy baseline: `01` run `22263496401`
3. Remediation generation: `02` run `22263586710` -> single PR `#120` merged
4. Apply merged remediation: `03` run `22263763659` success
5. Verify reduction: `04` run `22263825770` success
6. Restore verification baseline: `01` run `22264043779`

## 4) Key Metrics
- Pre baseline fail: **27**
- Vulnerable baseline fail: **137**
- Post-apply fail (04): **67**
- Reduced (vulnerable baseline -> post): **70**
- Restored baseline fail: **27**

## 5) Rescan Summary (from 04)
- baseline_fail: `137`
- post_fail: `67`
- reduced: `70`
- actionable_fail(terraform-capable): `0`
- manual_fail(exception/manual): `67`

## 6) Check-Level Comparison Table
| Check ID | Pre(no deploy) | Vulnerable baseline | Post-apply (04) | Restored baseline |
|---|---:|---:|---:|---:|
| `prowler-s3_bucket_no_mfa_delete` | 24 | 64 | 64 | 24 |
| `prowler-s3_bucket_secure_transport_policy` | 0 | 40 | 0 | 0 |
| `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports` | 0 | 30 | 0 | 0 |
| `prowler-iam_root_hardware_mfa_enabled` | 1 | 1 | 1 | 1 |
| `prowler-ec2_instance_profile_attached` | 1 | 1 | 1 | 1 |
| `prowler-ec2_ebs_volume_encryption` | 1 | 1 | 1 | 1 |

## 7) What Happened (detailed)
- Large increase came from intentionally vulnerable S3 buckets and SGs:
  - `prowler-s3_bucket_secure_transport_policy` increased by +40
  - `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports` increased by +30
- One-shot remediation removed terraform-capable demo checks in a single cycle:
  - secure transport policy: 40 -> 0
  - wide-open SG ingress: 30 -> 0
- Remaining FAIL after apply are manual-runbook class controls (not auto-remediated in this pipeline).

## 8) Restore Result
- Cleanup executed for demo-created resources (prefix-based):
  - Deleted SGs: 30
  - Deleted log groups: 20
  - Deleted buckets: 40
- Resource count after cleanup:
  - `vuln-*` buckets: 0
  - `vuln-sg-*`: 0
  - `/vuln/log-group-*`: 60
- Restored scan fail count: `27` (pre baseline was `27`)

## 9) Presenter Talk Track (for live demo)
1. Show pre baseline (`27`) as starting point.
2. Deploy vulnerable profile and rerun baseline (`137`).
3. Generate one consolidated remediation PR and merge once.
4. Show apply success and rescan reduction (`137 -> 67`, reduced `70`).
5. Explain why remaining FAIL are manual-runbook and separated from auto-remediable KPI.
6. Show cleanup and restored baseline run.

## 10) Status
- Task 1 execution: **completed**
- Demo reproducibility: **ready**
- Remaining work moved to Task 2/3 reports.
