resource "aws_default_security_group" "fix_default_sg_546f55e111" {
  vpc_id = "vpc-083ea82164cf21314"

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
