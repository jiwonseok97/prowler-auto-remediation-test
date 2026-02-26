resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_0a019152c4" {
  network_acl_id = "acl-018bc0f2b6dbf6914"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
