resource "aws_default_security_group" "fix_default_sg_5b0f692c1f" {
  vpc_id = "vpc-0bfe84cfb40a47cfe"

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
