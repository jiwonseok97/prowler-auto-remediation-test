resource "aws_default_security_group" "fix_default_sg_29c37863b4" {
  vpc_id = "vpc-03e0f46629506c747"

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
