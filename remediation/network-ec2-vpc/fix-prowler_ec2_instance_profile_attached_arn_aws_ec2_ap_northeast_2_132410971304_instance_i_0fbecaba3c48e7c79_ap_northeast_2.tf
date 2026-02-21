resource "null_resource" "fix_ec2_instance_profile_association_a7e4e4fdd1" {
  triggers = {
    instance_id  = "i-0fbecaba3c48e7c79"
    profile_name = "AmazonEKSAutoClusterRole"
    role_name    = "AmazonEKSAutoClusterRole"
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -uo pipefail
INSTANCE_ID="i-0fbecaba3c48e7c79"
PROFILE_NAME="AmazonEKSAutoClusterRole"
ROLE_NAME="AmazonEKSAutoClusterRole"
aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" >/dev/null 2>&1 || aws iam create-instance-profile --instance-profile-name "$PROFILE_NAME" || true
if [ -n "$ROLE_NAME" ]; then
  HAS_ROLE=$(aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" --query "InstanceProfile.Roles[?RoleName=='$ROLE_NAME'] | length(@)" --output text || true)
  if [ "$HAS_ROLE" = "0" ] || [ -z "$HAS_ROLE" ] || [ "$HAS_ROLE" = "None" ]; then
    aws iam add-role-to-instance-profile --instance-profile-name "$PROFILE_NAME" --role-name "$ROLE_NAME" || true
    sleep 10
  fi
fi
TARGET_ARN=$(aws iam get-instance-profile --instance-profile-name "$PROFILE_NAME" --query 'InstanceProfile.Arn' --output text)
ASSOC_ID=$(aws ec2 describe-iam-instance-profile-associations --region "$AWS_REGION" --filters Name=instance-id,Values="$INSTANCE_ID" --query 'IamInstanceProfileAssociations[0].AssociationId' --output text || true)
CURRENT_ARN=$(aws ec2 describe-iam-instance-profile-associations --region "$AWS_REGION" --filters Name=instance-id,Values="$INSTANCE_ID" --query 'IamInstanceProfileAssociations[0].IamInstanceProfile.Arn' --output text || true)
if [ "$ASSOC_ID" = "None" ] || [ -z "$ASSOC_ID" ]; then
  aws ec2 associate-iam-instance-profile --region "$AWS_REGION" --instance-id "$INSTANCE_ID" --iam-instance-profile Name="$PROFILE_NAME" || true
else
  if [ "$CURRENT_ARN" != "$TARGET_ARN" ]; then
    aws ec2 replace-iam-instance-profile-association --region "$AWS_REGION" --association-id "$ASSOC_ID" --iam-instance-profile Name="$PROFILE_NAME" || true
  fi
fi
exit 0
EOT
  }
}
