resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_d1a4f4e6c1" {
  network_acl_id = "acl-0bc682f441ce85c26"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
