resource "aws_default_security_group" "fix_default_sg_4b307bd4b8" {
  vpc_id = "vpc-0febd00ce0ff29158"

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
