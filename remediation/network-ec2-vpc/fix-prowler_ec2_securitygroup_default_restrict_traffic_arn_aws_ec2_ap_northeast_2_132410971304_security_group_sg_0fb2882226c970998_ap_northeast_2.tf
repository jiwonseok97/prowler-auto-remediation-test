resource "aws_default_security_group" "fix_default_sg_cdb7ee9ba7" {
  vpc_id = "vpc-019168b7be6e9f31a"

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
