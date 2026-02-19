resource "aws_network_acl_rule" "remediation_a0c3e003c7" {
  network_acl_id = "acl-0e50661d6d0d29136"
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 0
  to_port        = 0
}
