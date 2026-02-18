# network-ec2-vpc remediation snippet
resource "aws_security_group_rule" "deny_open_all_ingress_example" {
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["10.0.0.0/8"]
  security_group_id = "REPLACE_SG_ID"
  description       = "Restrict ingress to internal CIDR and HTTPS only"
}
