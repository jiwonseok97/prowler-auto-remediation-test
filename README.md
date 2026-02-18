# Prowler Auto Remediation Test

PoC repository for AWS IaC security automation using:
- Vulnerable Terraform baseline (`terraform/test_infra`)
- AI-generated remediation Terraform (`terraform/remediation`)
- Prowler scan result parsing and snippet-based remediation generation (`iac/scripts`)
- GitHub Actions pipeline for scan -> remediation branch -> PR -> apply

## Goals
- Keep vulnerable infra code separate and reusable.
- Generate remediation code from Prowler JSON findings for supported categories only:
  - `iam`
  - `s3`
  - `network-ec2-vpc`
  - `cloudtrail`
  - `cloudwatch`
- Preserve apply idempotency and protect singleton resources.
- Block destructive drift loops and unsafe replacement operations.

## Required Inputs
- GitHub Personal Access Token
- GitHub account/org name
- repo private 여부
- AWS_ACCESS_KEY_ID
- AWS_SECRET_ACCESS_KEY
- AWS_DEFAULT_REGION
- multi-region 여부
- AI model name + API key

## Quick Start
1. Create repo and scaffold interactively:
   - `python bootstrap_repo.py`
2. Configure GitHub Actions secrets in the created repo:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_DEFAULT_REGION`
   - `AI_MODEL`
   - `AI_API_KEY`
3. Trigger `Prowler Security Scan & AI Remediation` workflow.
4. Review PR `remediation-<run_id>`, merge it.
5. On merge to `main`, apply workflow runs and re-scan validates reduction of findings.

## Notes
- Some controls cannot be auto-remediated safely (for example org/FMS/root MFA).
- Unsupported findings are logged only.
- `terraform/test_infra` is intentionally vulnerable and must remain separate from remediation code.
