resource "aws_iam_role" "fix_ec2_instance_profile_role_a7e4e4fdd1" {
  name               = "prowler-remediation-ec2-role-i_0fbecaba3c48e7c79"
  assume_role_policy = "{\"Version\": \"2012-10-17\", \"Statement\": [{\"Effect\": \"Allow\", \"Principal\": {\"Service\": \"ec2.amazonaws.com\"}, \"Action\": \"sts:AssumeRole\"}]}"
}

resource "aws_iam_instance_profile" "fix_ec2_instance_profile_a7e4e4fdd1" {
  name = "prowler-remediation-ec2-profile-i_0fbecaba3c48e7c79"
  role = aws_iam_role.fix_ec2_instance_profile_role_a7e4e4fdd1.name
}

resource "null_resource" "fix_ec2_instance_profile_association_a7e4e4fdd1" {
  triggers = {
    instance_id  = "i-0fbecaba3c48e7c79"
    profile_name = aws_iam_instance_profile.fix_ec2_instance_profile_a7e4e4fdd1.name
  }

  provisioner "local-exec" {
    interpreter = ["/bin/bash", "-lc"]
    command     = <<-EOT
set -uo pipefail
INSTANCE_ID="i-0fbecaba3c48e7c79"
PROFILE_NAME="prowler-remediation-ec2-profile-i_0fbecaba3c48e7c79"
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
  depends_on = [aws_iam_instance_profile.fix_ec2_instance_profile_a7e4e4fdd1]
}
