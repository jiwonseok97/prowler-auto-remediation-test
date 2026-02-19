resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_3f5a395d75" {
  network_acl_id = "acl-0aefc1d1492a25a53"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
