resource "aws_network_acl_rule" "allow_ingress_tcp_port_3389_b815cd19a9" {
  network_acl_id = "acl-05b5345695d849863"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
