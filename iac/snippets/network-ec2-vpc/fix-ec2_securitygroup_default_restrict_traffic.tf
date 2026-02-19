resource "aws_default_security_group" "fix_default_sg" {
  vpc_id = var.vpc_id

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
