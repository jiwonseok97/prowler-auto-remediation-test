resource "aws_default_security_group" "fix_default_sg_691143220e" {
  vpc_id = "vpc-0958e25bd5e60fe30"

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
