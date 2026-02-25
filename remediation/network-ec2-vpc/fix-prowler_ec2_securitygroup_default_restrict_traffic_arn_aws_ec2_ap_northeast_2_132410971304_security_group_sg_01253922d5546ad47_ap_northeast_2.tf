resource "aws_default_security_group" "fix_default_sg_803f4c50c2" {
  vpc_id = "vpc-01078e2c869d87b89"

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
