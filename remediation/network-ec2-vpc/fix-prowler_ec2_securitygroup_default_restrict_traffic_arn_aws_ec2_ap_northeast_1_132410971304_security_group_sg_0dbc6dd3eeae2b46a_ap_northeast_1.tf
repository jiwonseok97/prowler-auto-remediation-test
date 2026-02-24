resource "aws_default_security_group" "fix_default_sg_b0207cdae5" {
  vpc_id = "vpc-0c6698ed5193c8e95"

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
