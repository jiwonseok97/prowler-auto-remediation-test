resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_6a0bbfc6f9" {
  network_acl_id = "acl-01c3b6a34d02b0c30"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
