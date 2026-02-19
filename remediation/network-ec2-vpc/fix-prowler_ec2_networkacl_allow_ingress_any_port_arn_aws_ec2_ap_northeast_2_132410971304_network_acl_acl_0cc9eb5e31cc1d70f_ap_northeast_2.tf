resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_0b5d90591c" {
  network_acl_id = "acl-0cc9eb5e31cc1d70f"
  egress         = false
  rule_number    = 51
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
