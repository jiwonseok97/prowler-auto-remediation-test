resource "aws_network_acl_rule" "remediate_tcp_port_3389_d9d1fec462" {
  network_acl_id = "acl-010aa48232860e9d8"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
