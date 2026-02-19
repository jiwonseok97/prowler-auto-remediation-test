resource "aws_default_security_group" "fix_default_sg_e3067708ac" {
  vpc_id = "vpc-0565167ce4f7cc871"

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
