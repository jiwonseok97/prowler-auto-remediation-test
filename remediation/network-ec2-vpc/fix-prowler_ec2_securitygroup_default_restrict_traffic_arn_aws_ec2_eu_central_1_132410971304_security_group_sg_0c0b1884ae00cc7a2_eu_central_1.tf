resource "aws_default_security_group" "fix_default_sg_a446c38a20" {
  vpc_id = "vpc-0d7d5c421a1cea550"

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
