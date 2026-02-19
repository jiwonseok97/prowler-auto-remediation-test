resource "aws_default_security_group" "fix_default_sg_7b8bb569c0" {
  vpc_id = "vpc-0204bfe3f225cb78d"

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
