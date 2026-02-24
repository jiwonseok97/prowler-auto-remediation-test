resource "aws_default_security_group" "fix_default_sg_18dc05cf0f" {
  vpc_id = "vpc-0e9d54f50e6b87984"

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
