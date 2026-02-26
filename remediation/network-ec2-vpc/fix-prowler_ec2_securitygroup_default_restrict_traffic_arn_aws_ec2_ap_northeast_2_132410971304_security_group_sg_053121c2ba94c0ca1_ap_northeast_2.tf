resource "aws_default_security_group" "fix_default_sg_fe9fd09111" {
  vpc_id = "vpc-0b504cb23a27665c8"

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
