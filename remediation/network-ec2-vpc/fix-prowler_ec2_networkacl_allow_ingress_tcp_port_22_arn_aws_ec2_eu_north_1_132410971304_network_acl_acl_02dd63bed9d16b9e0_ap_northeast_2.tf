resource "aws_network_acl_rule" "allow_ingress_tcp_port_22_40fb784cfe" {
  network_acl_id = "acl-02dd63bed9d16b9e0"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}
