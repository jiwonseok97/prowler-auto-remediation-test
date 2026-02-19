resource "aws_network_acl_rule" "remediation_7864a97953" {
  network_acl_id = "acl-0ebd5da14e1dbdbc7"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
