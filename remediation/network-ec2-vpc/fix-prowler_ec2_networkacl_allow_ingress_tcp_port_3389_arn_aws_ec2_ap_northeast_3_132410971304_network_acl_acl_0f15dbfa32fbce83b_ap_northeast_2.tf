resource "aws_network_acl_rule" "remediate_ec2_networkacl_allow_ingress_tcp_port_3389_a8936417b7" {
  network_acl_id = "acl-0f15dbfa32fbce83b"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
