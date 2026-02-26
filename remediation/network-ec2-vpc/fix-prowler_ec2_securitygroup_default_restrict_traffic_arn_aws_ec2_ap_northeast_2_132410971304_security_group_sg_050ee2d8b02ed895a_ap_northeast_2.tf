resource "aws_default_security_group" "fix_default_sg_6ceb512c51" {
  vpc_id = "vpc-02a4d7f3c99e7aa91"

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
