resource "aws_default_security_group" "fix_default_sg_9c2d87be3c" {
  vpc_id = "vpc-0b6ca3673d548c906"

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
