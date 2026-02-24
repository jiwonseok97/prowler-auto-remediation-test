resource "aws_default_security_group" "fix_default_sg_4a90415df5" {
  vpc_id = "vpc-07026a62847200142"

  ingress = []
  egress  = []

  lifecycle {
    ignore_changes = [
      name,
      description,
      revoke_rules_on_delete,
      tags,
      tags_all
    ]
  }
}
