resource "aws_default_security_group" "fix_default_sg_2c885944ae" {
  vpc_id = "vpc-05b030359c392a304"

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
