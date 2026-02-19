resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_674c0d8908" {
  network_acl_id = "acl-0bc682f441ce85c26"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
