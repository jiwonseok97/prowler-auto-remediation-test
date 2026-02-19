resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_97607c8130" {
  network_acl_id = "acl-01c3b6a34d02b0c30"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
