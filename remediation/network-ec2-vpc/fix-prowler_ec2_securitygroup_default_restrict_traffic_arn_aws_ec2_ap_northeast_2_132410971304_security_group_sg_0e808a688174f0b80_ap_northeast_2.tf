resource "aws_default_security_group" "fix_default_sg_4a13eaa168" {
  vpc_id = "vpc-0ad18cac76a0ab778"

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
