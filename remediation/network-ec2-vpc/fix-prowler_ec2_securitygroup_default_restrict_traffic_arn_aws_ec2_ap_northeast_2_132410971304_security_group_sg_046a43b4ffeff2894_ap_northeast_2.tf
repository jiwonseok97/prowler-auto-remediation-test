resource "aws_default_security_group" "fix_default_sg_ad6c0701c8" {
  vpc_id = "vpc-00073037771b033e0"

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
