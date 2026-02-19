resource "aws_network_acl_rule" "remediate_tcp_port_22_ingress_e88d67b6ff" {
  network_acl_id = "acl-0057dcde73056600a"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
