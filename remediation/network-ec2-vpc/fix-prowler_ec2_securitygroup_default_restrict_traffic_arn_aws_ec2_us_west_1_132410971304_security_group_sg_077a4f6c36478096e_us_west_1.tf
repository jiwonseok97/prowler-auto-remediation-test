resource "aws_default_security_group" "fix_default_sg_a52b5b032a" {
  vpc_id = "vpc-00176713df46332e8"

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
