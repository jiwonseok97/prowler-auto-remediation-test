resource "aws_default_security_group" "fix_default_sg_57ec0651da" {
  vpc_id = "vpc-023b3558059c392df"

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
