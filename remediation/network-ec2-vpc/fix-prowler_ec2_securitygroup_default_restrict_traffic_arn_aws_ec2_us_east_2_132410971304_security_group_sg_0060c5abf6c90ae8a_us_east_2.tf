resource "aws_default_security_group" "fix_default_sg_9169076c19" {
  vpc_id = "vpc-0ee76660afd5ade09"

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
