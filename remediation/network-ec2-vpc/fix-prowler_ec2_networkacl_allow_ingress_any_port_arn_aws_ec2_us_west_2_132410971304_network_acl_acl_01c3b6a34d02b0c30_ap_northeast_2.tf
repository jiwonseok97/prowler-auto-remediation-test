resource "aws_network_acl_rule" "remediation_dfb167ecf2" {
  network_acl_id = "acl-01c3b6a34d02b0c30"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
