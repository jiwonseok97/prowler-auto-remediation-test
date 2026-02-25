resource "aws_default_security_group" "fix_default_sg_bad4f65bb6" {
  vpc_id = "vpc-06f1691190269dd4e"

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
