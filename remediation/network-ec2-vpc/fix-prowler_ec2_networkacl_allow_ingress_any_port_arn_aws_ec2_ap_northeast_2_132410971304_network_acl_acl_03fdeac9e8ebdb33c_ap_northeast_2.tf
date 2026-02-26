resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_d7f933c791" {
  network_acl_id = "acl-03fdeac9e8ebdb33c"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
