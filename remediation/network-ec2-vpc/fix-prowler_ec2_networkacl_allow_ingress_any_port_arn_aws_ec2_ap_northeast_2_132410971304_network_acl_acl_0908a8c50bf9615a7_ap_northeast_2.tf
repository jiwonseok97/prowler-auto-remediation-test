resource "aws_network_acl_rule" "fix_network_acl_ingress_deny_700bc0a413" {
  network_acl_id = "acl-0908a8c50bf9615a7"
  egress         = false
  rule_number    = 253
  protocol       = "-1"
  rule_action    = "deny"
  cidr_block     = "0.0.0.0/0"
  lifecycle {
    ignore_changes = [icmp_type, icmp_code]
  }
}
