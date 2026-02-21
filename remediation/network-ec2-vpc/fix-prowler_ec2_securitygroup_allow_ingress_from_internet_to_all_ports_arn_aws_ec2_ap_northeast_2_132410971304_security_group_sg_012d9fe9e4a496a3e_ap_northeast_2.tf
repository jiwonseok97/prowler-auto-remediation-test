resource "null_resource" "fix_sg_restrict_world_ingress_d3e11e813a" {
  triggers = {
    security_group_id = "sg-012d9fe9e4a496a3e"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -euo pipefail
SG_ID="sg-012d9fe9e4a496a3e"
RULE_IDS=$(aws ec2 describe-security-group-rules --region "$AWS_REGION" \
  --filters Name=group-id,Values="$SG_ID" Name=is-egress,Values=false \
  --query 'SecurityGroupRules[?CidrIpv4==`0.0.0.0/0` || CidrIpv6==`::/0`].SecurityGroupRuleId' \
  --output text || true)
if [ -n "$RULE_IDS" ] && [ "$RULE_IDS" != "None" ]; then
  aws ec2 revoke-security-group-ingress --region "$AWS_REGION" --group-id "$SG_ID" --security-group-rule-ids $RULE_IDS || true
fi
EOT
  }
}
