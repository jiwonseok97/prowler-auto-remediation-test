resource "aws_default_security_group" "fix_default_sg_9d57894e46" {
  vpc_id = "vpc-0ebb6305e7a19187f"

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
