resource "aws_default_security_group" "fix_default_sg_ee6298bf62" {
  vpc_id = "vpc-018685e78ded4212d"

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
