resource "aws_default_security_group" "fix_default_sg_689a757bfd" {
  vpc_id = "vpc-00673f54bd91d54bf"

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
