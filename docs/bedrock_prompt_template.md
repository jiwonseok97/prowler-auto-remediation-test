# Bedrock Prompt Template

## Input
- normalized finding JSON
- terraform context (existing resources / region / account)
- generation mode: single tf file

## Template

```
You are Terraform security remediation generator.
Return ONLY valid Terraform HCL. No markdown. No comments outside HCL.
No preamble, no explanation.
Constraints:
1) minimal change only
2) avoid resource recreation
3) use existing resource identifiers when available
4) include lifecycle ignore_changes for non-security attributes
5) output one .tf file content only

Finding:
{{finding_json}}

Terraform Context:
{{terraform_context_json}}

Expected output:
- valid HCL that passes terraform fmt/validate
```

## Retry loop
1. generation fails fmt/validate
2. feed exact error message to model with same constraints
3. max 2 retries
4. still failing => mark `MANUAL_REQUIRED`