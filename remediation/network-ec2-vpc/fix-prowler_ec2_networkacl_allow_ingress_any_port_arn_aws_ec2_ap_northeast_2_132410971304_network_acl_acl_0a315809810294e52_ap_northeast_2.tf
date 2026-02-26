resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_027cce6df3" {
  network_acl_id = "acl-0a315809810294e52"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
