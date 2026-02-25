resource "aws_default_security_group" "fix_default_sg_248a9650db" {
  vpc_id = "vpc-099ef085633a8d818"

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
