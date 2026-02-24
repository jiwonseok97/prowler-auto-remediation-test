resource "aws_default_security_group" "fix_default_sg_dc52c8cac8" {
  vpc_id = "vpc-00cf7259136c9cfd3"

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
