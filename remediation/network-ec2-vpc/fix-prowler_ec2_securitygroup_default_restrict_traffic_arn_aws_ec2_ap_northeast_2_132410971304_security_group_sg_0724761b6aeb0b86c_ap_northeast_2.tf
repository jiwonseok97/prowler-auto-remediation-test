resource "aws_default_security_group" "fix_default_sg_31374667c6" {
  vpc_id = "vpc-0f3dce5a9a8b98027"

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
