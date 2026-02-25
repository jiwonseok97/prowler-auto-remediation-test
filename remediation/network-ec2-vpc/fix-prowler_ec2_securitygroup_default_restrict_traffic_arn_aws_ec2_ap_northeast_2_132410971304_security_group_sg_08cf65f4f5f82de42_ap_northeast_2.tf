resource "aws_default_security_group" "fix_default_sg_109afe3389" {
  vpc_id = "vpc-01127842030506ff1"

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
