resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_dc4506294c" {
  network_acl_id = "acl-010aa48232860e9d8"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
