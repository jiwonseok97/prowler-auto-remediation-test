resource "aws_default_security_group" "fix_default_sg_18ebff56d1" {
  vpc_id = "vpc-00ad0a6f6708025be"

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
