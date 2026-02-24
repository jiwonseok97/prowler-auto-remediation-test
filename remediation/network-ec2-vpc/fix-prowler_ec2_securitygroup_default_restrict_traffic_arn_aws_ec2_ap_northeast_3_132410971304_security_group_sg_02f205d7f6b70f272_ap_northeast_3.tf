resource "aws_default_security_group" "fix_default_sg_e4975d0b38" {
  vpc_id = "vpc-04eb6666298723a01"

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
