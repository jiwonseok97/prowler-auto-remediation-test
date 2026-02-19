resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_eb02744280" {
  network_acl_id = "acl-0717044c683de2f8a"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
