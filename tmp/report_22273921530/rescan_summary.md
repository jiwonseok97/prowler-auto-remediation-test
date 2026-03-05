## Rescan Summary
- baseline_fail: 251
- post_fail: 135
- reduced: 116 (baseline -> current)
- actionable_fail(terraform-capable): 0
- manual_fail(exception/manual): 135

### Remaining FAIL (All)
| Remaining Check ID | Count |
|---|---:|
| `prowler-ec2_ebs_volume_encryption` | 1 |
| `prowler-ec2_instance_profile_attached` | 1 |
| `prowler-iam_root_hardware_mfa_enabled` | 1 |
| `prowler-s3_bucket_no_mfa_delete` | 132 |

### Terraform-Capable FAIL (Auto/Review)
| Check ID (Terraform-Capable) | Count |
|---|---:|
| none | 0 |

### Manual-Runbook FAIL (Exception/Manual)
| Check ID (Manual Runbook) | Count |
|---|---:|
| `prowler-ec2_ebs_volume_encryption` | 1 |
| `prowler-ec2_instance_profile_attached` | 1 |
| `prowler-iam_root_hardware_mfa_enabled` | 1 |
| `prowler-s3_bucket_no_mfa_delete` | 132 |

### What We Can Continue Now (Pipeline-Auto/Review)
- Terraform-capable remaining FAIL is 0.
- Next action: focus on manual-runbook controls.

### What Should Be Planned Later (Manual/Exception)
- Remaining manual-runbook FAIL: 135
- Typical items require account security policy, organizational controls, or manual operations.
