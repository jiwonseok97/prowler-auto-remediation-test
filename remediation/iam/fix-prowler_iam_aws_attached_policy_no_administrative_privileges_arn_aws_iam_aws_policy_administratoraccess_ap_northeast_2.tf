resource "null_resource" "fix_iam_detach_admin_policy_694c8b2458" {
  triggers = {
    policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -euo pipefail
POLICY_ARN="arn:aws:iam::aws:policy/AdministratorAccess"
USERS=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query "PolicyUsers[].UserName" --output text || true)
for U in $USERS; do aws iam detach-user-policy --user-name "$U" --policy-arn "$POLICY_ARN" || true; done
ROLES=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query "PolicyRoles[].RoleName" --output text || true)
for R in $ROLES; do aws iam detach-role-policy --role-name "$R" --policy-arn "$POLICY_ARN" || true; done
GROUPS=$(aws iam list-entities-for-policy --policy-arn "$POLICY_ARN" --query "PolicyGroups[].GroupName" --output text || true)
for G in $GROUPS; do aws iam detach-group-policy --group-name "$G" --policy-arn "$POLICY_ARN" || true; done
EOT
  }
}
