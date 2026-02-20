resource "aws_default_security_group" "fix_default_sg_1287e1b8d8" {
  vpc_id = "vpc-011b7fd144cd2880e"

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
