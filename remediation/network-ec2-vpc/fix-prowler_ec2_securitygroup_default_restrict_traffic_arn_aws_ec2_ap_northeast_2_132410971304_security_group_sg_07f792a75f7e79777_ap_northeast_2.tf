resource "aws_default_security_group" "fix_default_sg_caf327c28d" {
  vpc_id = "vpc-0547801a9d958ea44"

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
