resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_99b74d2457" {
  network_acl_id = "acl-0e8faca2c3368de06"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
