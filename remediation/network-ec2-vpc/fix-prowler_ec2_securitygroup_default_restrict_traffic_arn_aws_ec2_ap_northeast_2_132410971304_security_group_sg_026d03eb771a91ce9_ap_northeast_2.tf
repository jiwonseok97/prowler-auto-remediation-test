resource "aws_default_security_group" "fix_default_sg_491c2b9cd8" {
  vpc_id = "vpc-0c88fa3f0008c0495"

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
