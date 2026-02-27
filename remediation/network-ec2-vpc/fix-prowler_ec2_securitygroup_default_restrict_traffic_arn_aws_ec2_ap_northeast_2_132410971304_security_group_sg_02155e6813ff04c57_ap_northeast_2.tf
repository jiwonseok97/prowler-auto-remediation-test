resource "aws_default_security_group" "fix_default_sg_0a1b614fc0" {
  vpc_id = "vpc-0f79f0d05fa71dd51"

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
