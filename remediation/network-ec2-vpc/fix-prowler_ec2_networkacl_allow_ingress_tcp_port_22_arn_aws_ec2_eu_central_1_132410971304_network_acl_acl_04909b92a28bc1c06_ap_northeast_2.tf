resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_5aee069365" {
  network_acl_id = "acl-04909b92a28bc1c06"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
