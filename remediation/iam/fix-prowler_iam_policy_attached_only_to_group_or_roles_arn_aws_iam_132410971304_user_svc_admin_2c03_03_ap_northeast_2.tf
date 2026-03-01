resource "null_resource" "fix_iam_user_policy_attachments_d523b12881" {
  triggers = {
    user_name = "svc-admin-2c03-03"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -uo pipefail
USER_NAME="svc-admin-2c03-03"
ATTACHED=$(aws iam list-attached-user-policies --user-name "$USER_NAME" --query "AttachedPolicies[].PolicyArn" --output text || true)
for P in $ATTACHED; do
  aws iam detach-user-policy --user-name "$USER_NAME" --policy-arn "$P" || true
done
INLINE=$(aws iam list-user-policies --user-name "$USER_NAME" --query "PolicyNames[]" --output text || true)
for PN in $INLINE; do
  aws iam delete-user-policy --user-name "$USER_NAME" --policy-name "$PN" || true
done
exit 0
EOT
  }
}
