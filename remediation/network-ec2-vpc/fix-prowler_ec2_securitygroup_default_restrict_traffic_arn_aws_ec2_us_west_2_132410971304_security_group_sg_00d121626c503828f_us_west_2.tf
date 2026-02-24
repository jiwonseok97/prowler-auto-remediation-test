resource "aws_default_security_group" "fix_default_sg_abf17a73de" {
  vpc_id = "vpc-01f7b7a4e5c20a668"

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
