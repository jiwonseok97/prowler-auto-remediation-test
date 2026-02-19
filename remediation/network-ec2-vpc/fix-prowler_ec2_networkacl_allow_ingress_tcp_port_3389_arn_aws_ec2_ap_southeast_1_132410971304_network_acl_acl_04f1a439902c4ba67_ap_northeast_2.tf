resource "aws_network_acl_rule" "allow_ingress_tcp_port_3389_9b48ea50dd" {
  network_acl_id = "acl-04f1a439902c4ba67"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
