resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_d8fabececc" {
  network_acl_id = "acl-0e50661d6d0d29136"
  egress         = false
  rule_number    = 252
  protocol       = "6"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  from_port      = 3389
  to_port        = 3389
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
