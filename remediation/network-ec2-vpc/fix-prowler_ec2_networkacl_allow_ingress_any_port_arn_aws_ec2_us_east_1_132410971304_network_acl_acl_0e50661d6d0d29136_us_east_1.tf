resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_2221f494b9" {
  network_acl_id = "acl-0e50661d6d0d29136"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
