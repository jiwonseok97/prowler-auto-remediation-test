#!/usr/bin/env python3
"""Replace old cleanup+deploy steps in scan-cis.yml with S3-backend destroy+apply pattern."""
import re, sys
from pathlib import Path

wf = Path('.github/workflows/scan-cis.yml')
content = wf.read_text(encoding='utf-8')
lines = content.splitlines(keepends=True)

# Find line indices (0-based)
# Keep lines 0-50 (header through "Setup Terraform" step)
# Keep lines 218+ (blank line then "Setup Python" step onward)
# Replace lines 51-217 (old cleanup + deploy steps)

new_section = """\
      - name: Deploy vulnerable infra
        if: inputs.deploy_vulnerable == true
        shell: bash
        run: |
          set -euo pipefail
          STATE_BUCKET="prowler-auto-tfstate-${AWS_ACCOUNT_ID}"
          STATE_KEY="vulnerable_infra_test/terraform.tfstate"

          # 1. Ensure Terraform state bucket exists
          echo "==> ensure state bucket: $STATE_BUCKET"
          if ! aws s3api head-bucket --bucket "$STATE_BUCKET" 2>/dev/null; then
            aws s3api create-bucket \\
              --bucket "$STATE_BUCKET" \\
              --region "$AWS_REGION" \\
              --create-bucket-configuration LocationConstraint="$AWS_REGION"
            aws s3api put-bucket-versioning \\
              --bucket "$STATE_BUCKET" \\
              --versioning-configuration Status=Enabled
            echo "state bucket created"
          fi

          # 2. Terraform init with S3 backend
          echo "==> terraform init (S3 backend)"
          terraform -chdir=terraform/vulnerable_infra_test init -input=false -reconfigure \\
            -backend-config="bucket=${STATE_BUCKET}" \\
            -backend-config="key=${STATE_KEY}" \\
            -backend-config="region=${AWS_REGION}"

          # 3. Destroy previous run (uses stored state, idempotent)
          # - force_destroy=true on S3 buckets: Terraform empties + deletes them
          # - || true: no-op on first run; tolerates KMS pending deletion
          echo "==> terraform destroy (clean previous state)"
          terraform -chdir=terraform/vulnerable_infra_test destroy \\
            -auto-approve -input=false \\
            -var account_id="${{ inputs.account_id }}" \\
            -var region="${AWS_REGION}" || true

          # 4. Fallback CLI cleanup (orphaned resources outside Terraform state)
          set +e
          echo "==> fallback: cloudtrail trail"
          aws cloudtrail delete-trail --region "$AWS_REGION" --name vuln-trail || true
          sleep 5

          echo "==> fallback: iam users"
          for uname in vuln-user vuln-demo-direct-policy-user; do
            for pol in vuln-wildcard-policy vuln-demo-readonly-policy; do
              aws iam detach-user-policy --user-name "$uname" \\
                --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/$pol" 2>/dev/null || true
            done
            aws iam delete-user --user-name "$uname" 2>/dev/null || true
          done
          aws iam delete-policy \\
            --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/vuln-wildcard-policy" || true
          aws iam delete-policy \\
            --policy-arn "arn:aws:iam::${AWS_ACCOUNT_ID}:policy/vuln-demo-readonly-policy" || true

          echo "==> fallback: cloudwatch log groups"
          mapfile -t LOG_GROUPS < <(
            aws logs describe-log-groups --region "$AWS_REGION" \\
              --query "logGroups[?starts_with(logGroupName, '/vuln/log-group')].logGroupName" \\
              --output text | tr '\\t' '\\n' | sed '/^$/d'
          )
          for lg in "${LOG_GROUPS[@]}"; do
            aws logs delete-log-group --region "$AWS_REGION" --log-group-name "$lg" || true
          done

          echo "==> fallback: s3 buckets"
          mapfile -t BUCKETS < <(
            aws s3api list-buckets \\
              --query "Buckets[?starts_with(Name,'vuln-demo-')||starts_with(Name,'vuln-cloudtrail-')].Name" \\
              --output text | tr '\\t' '\\n' | sed '/^$/d'
          )
          for b in "${BUCKETS[@]}"; do
            echo "  force-delete $b"
            aws s3 rm "s3://$b" --recursive || true
            while IFS=$'\\t' read -r key vid; do
              [ -n "$key" ] && aws s3api delete-object \\
                --bucket "$b" --key "$key" --version-id "$vid" 2>/dev/null || true
            done < <(aws s3api list-object-versions --bucket "$b" \\
              --query 'Versions[].{Key:Key,VersionId:VersionId}' \\
              --output text 2>/dev/null)
            while IFS=$'\\t' read -r key vid; do
              [ -n "$key" ] && aws s3api delete-object \\
                --bucket "$b" --key "$key" --version-id "$vid" 2>/dev/null || true
            done < <(aws s3api list-object-versions --bucket "$b" \\
              --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' \\
              --output text 2>/dev/null)
            aws s3 rb "s3://$b" --force || true
          done

          echo "==> fallback: vpcs"
          mapfile -t VPCS < <(
            aws ec2 describe-vpcs --region "$AWS_REGION" \\
              --filters Name=tag:ProwlerDemo,Values=vulnerable_infra_test \\
              --query 'Vpcs[].VpcId' \\
              --output text | tr '\\t' '\\n' | sed '/^$/d'
          )
          for vpc_id in "${VPCS[@]}"; do
            echo "  cleanup vpc $vpc_id"
            mapfile -t SNS < <(aws ec2 describe-subnets --region "$AWS_REGION" \\
              --filters Name=vpc-id,Values="$vpc_id" \\
              --query 'Subnets[].SubnetId' --output text | tr '\\t' '\\n' | sed '/^$/d')
            for sn in "${SNS[@]}"; do
              aws ec2 delete-subnet --region "$AWS_REGION" --subnet-id "$sn" || true
            done
            mapfile -t IGWS < <(aws ec2 describe-internet-gateways --region "$AWS_REGION" \\
              --filters Name=attachment.vpc-id,Values="$vpc_id" \\
              --query 'InternetGateways[].InternetGatewayId' \\
              --output text | tr '\\t' '\\n' | sed '/^$/d')
            for igw in "${IGWS[@]}"; do
              aws ec2 detach-internet-gateway --region "$AWS_REGION" \\
                --internet-gateway-id "$igw" --vpc-id "$vpc_id" || true
              aws ec2 delete-internet-gateway --region "$AWS_REGION" \\
                --internet-gateway-id "$igw" || true
            done
            mapfile -t RTBS < <(aws ec2 describe-route-tables --region "$AWS_REGION" \\
              --filters Name=vpc-id,Values="$vpc_id" Name=association.main,Values=false \\
              --query 'RouteTables[].RouteTableId' --output text | tr '\\t' '\\n' | sed '/^$/d')
            for rtb in "${RTBS[@]}"; do
              aws ec2 delete-route-table --region "$AWS_REGION" --route-table-id "$rtb" || true
            done
            mapfile -t CSGS < <(aws ec2 describe-security-groups --region "$AWS_REGION" \\
              --filters Name=vpc-id,Values="$vpc_id" \\
              --query "SecurityGroups[?GroupName!='default'].GroupId" \\
              --output text | tr '\\t' '\\n' | sed '/^$/d')
            for sg in "${CSGS[@]}"; do
              aws ec2 delete-security-group --region "$AWS_REGION" --group-id "$sg" || true
            done
            aws ec2 delete-vpc --region "$AWS_REGION" --vpc-id "$vpc_id" || true
          done

          echo "==> fallback: kms keys"
          mapfile -t KMS_ARNS < <(
            aws resourcegroupstaggingapi get-resources --region "$AWS_REGION" \\
              --tag-filters Key=ProwlerDemo,Values=vulnerable_infra_test \\
              --resource-type-filters kms \\
              --query "ResourceTagMappingList[].ResourceARN" \\
              --output text 2>/dev/null | tr '\\t' '\\n' | sed '/^$/d'
          )
          for key_arn in "${KMS_ARNS[@]}"; do
            key_id="${key_arn##*/}"
            aws kms schedule-key-deletion --region "$AWS_REGION" \\
              --key-id "$key_id" --pending-window-in-days 7 || true
          done
          set -e

          # 5. Deploy fresh vulnerable infra
          echo "==> terraform apply"
          terraform -chdir=terraform/vulnerable_infra_test apply \\
            -auto-approve -input=false \\
            -var account_id="${{ inputs.account_id }}" \\
            -var region="${AWS_REGION}"

"""

header = lines[:51]   # lines 1-51 (0-indexed 0-50)
footer = lines[218:]  # line 219 onward (blank line before "Setup Python")

with open('.github/workflows/scan-cis.yml', 'w', encoding='utf-8') as f:
    f.writelines(header)
    f.write(new_section)
    f.writelines(footer)

print(f"OK: wrote {len(header)} header + {len(new_section.splitlines())} new + {len(footer)} footer lines")
