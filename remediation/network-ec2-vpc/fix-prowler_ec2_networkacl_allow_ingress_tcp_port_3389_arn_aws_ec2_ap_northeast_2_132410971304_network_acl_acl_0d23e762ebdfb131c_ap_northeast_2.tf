resource "aws_network_acl_rule" "remediate_tcp_port_3389_eddc151489" {
  network_acl_id = "acl-0d23e762ebdfb131c"
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
}
