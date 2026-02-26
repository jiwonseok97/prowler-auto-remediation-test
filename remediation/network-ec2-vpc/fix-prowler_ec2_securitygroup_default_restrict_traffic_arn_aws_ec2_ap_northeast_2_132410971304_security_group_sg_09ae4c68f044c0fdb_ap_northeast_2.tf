resource "aws_default_security_group" "fix_default_sg_f1fb5ec56f" {
  vpc_id = "vpc-0da1d295a59896c0e"

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
