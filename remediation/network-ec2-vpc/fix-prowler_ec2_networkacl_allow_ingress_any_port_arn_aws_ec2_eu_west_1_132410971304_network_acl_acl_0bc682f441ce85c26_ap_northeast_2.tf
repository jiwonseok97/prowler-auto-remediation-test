resource "aws_network_acl_rule" "remediation_1f91d91ef5" {
  network_acl_id = "acl-0bc682f441ce85c26"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
