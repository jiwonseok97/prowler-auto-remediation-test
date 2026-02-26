resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_90397b3da6" {
  network_acl_id = "acl-018bc0f2b6dbf6914"
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
