resource "null_resource" "fix_sg_restrict_world_ingress_7db7761f47" {
  triggers = {
    security_group_id = "sg-0d5fef1d086e7aec0"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -euo pipefail
SG_ID="sg-0d5fef1d086e7aec0"
RULE_IDS=$(aws ec2 describe-security-group-rules --region "$AWS_REGION" \
  --filters Name=group-id,Values="$SG_ID" \
  --query 'SecurityGroupRules[?IsEgress==`false` && (CidrIpv4==`0.0.0.0/0` || CidrIpv6==`::/0`)].SecurityGroupRuleId' \
  --output text || true)
if [ -n "$RULE_IDS" ] && [ "$RULE_IDS" != "None" ]; then
  aws ec2 revoke-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --security-group-rule-ids $RULE_IDS || true
fi
EOT
  }
}
