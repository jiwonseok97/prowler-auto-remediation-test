## Rescan Summary
- baseline_fail: 48
- post_fail: 33
- reduced: 15 (baseline -> current)
- actionable_fail(terraform-capable): 5
- manual_fail(exception/manual): 28

### Remaining FAIL (All)
| Remaining Check ID | Count |
|---|---:|
| `prowler-ec2_ebs_volume_encryption` | 1 |
| `prowler-ec2_instance_profile_attached` | 1 |
| `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports` | 3 |
| `prowler-iam_root_hardware_mfa_enabled` | 1 |
| `prowler-s3_bucket_no_mfa_delete` | 27 |

### Terraform-Capable FAIL (Auto/Review)
| Check ID (Terraform-Capable) | Count |
|---|---:|
| `prowler-ec2_ebs_volume_encryption` | 1 |
| `prowler-ec2_instance_profile_attached` | 1 |
| `prowler-ec2_securitygroup_allow_ingress_from_internet_to_all_ports` | 3 |

### Manual-Runbook FAIL (Exception/Manual)
| Check ID (Manual Runbook) | Count |
|---|---:|
| `prowler-iam_root_hardware_mfa_enabled` | 1 |
| `prowler-s3_bucket_no_mfa_delete` | 27 |
